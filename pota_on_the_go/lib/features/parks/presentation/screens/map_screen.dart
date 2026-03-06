import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../home/presentation/providers/home_shell_providers.dart';
import '../../../spots/data/models/spot_model.dart';
import '../../../spots/data/repositories/spot_repository.dart';
// Removed embedded SpotsScreen per UX change: show only the map on main screen
import '../../data/models/park_model.dart';
import '../providers/park_local_provider.dart';
import 'park_detail_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  static const _initialZoom = 5.0;
  static const _mapTilerApiKey = String.fromEnvironment('MAPTILER_API_KEY');
  static const _mapTilerLightUrl =
      'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key={key}';
  static const _mapTilerDarkUrl =
      'https://api.maptiler.com/maps/backdrop/{z}/{x}/{y}.png?key={key}';
  static const _fallbackTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final AnimationController _refreshController;
  late final NetworkTileProvider _tileProvider;

  LatLngBounds? _visibleBounds;
  double _currentZoom = _initialZoom;
  bool _isLocating = false;
  bool _isRefreshingParks = false;
  bool _isMapReady = false;
  bool _showParks = false;
  String _searchQuery = '';
  MapFocusRequest? _pendingFocusRequest;
  Timer? _debounceTimer;

  bool get _hasMapTilerKey => _mapTilerApiKey.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _tileProvider = NetworkTileProvider(
      cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: 350 * 1024 * 1024,
        overrideFreshAge: const Duration(days: 14),
        tileKeyGenerator: _mapTileKeyGenerator,
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _tileProvider.dispose();
    _mapController.dispose();
    _searchFocusNode
      ..removeListener(_handleSearchFocusChanged)
      ..dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parksAsync = ref.watch(localParksProvider);
    final spotsAsync = ref.watch(currentSpotsProvider);
    final theme = Theme.of(context);
    final tileUrl = _hasMapTilerKey
        ? theme.brightness == Brightness.dark
              ? _mapTilerDarkUrl
              : _mapTilerLightUrl
        : _fallbackTileUrl;

    ref.listen<MapFocusRequest?>(mapFocusRequestProvider, (previous, next) {
      if (next == null) {
        return;
      }

      _pendingFocusRequest = next;
      final parks = parksAsync.asData?.value;
      if (parks != null) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!mounted) {
            return;
          }
          _applyPendingFocus(parks);
        });
      }
    });

    return parksAsync.when(
      data: (parks) =>
          _buildMapBody(context, theme, tileUrl, parks, spotsAsync),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildMessageCard(
        context,
        icon: Icons.error_outline,
        title: 'Harita verisi yüklenemedi.',
        subtitle: '$error',
        actionLabel: 'Tekrar dene',
        onPressed: () => ref.invalidate(localParksProvider),
      ),
    );
  }

  Widget _buildMapBody(
    BuildContext context,
    ThemeData theme,
    String tileUrl,
    List<ParkModel> parks,
    AsyncValue<List<SpotModel>> spotsAsync,
  ) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardVisible = viewInsets.bottom > 0;
    final validParks = parks
        .where(
          (park) =>
              park.latitude != 0 &&
              park.longitude != 0 &&
              park.latitude >= -90 &&
              park.latitude <= 90 &&
              park.longitude >= -180 &&
              park.longitude <= 180,
        )
        .toList(growable: false);
    if (validParks.isEmpty) {
      return _buildMessageCard(
        context,
        icon: Icons.location_off_outlined,
        title: 'Haritada gösterilecek koordinat bulunamadı.',
      );
    }

    final initialCenter = LatLng(
      validParks.first.latitude,
      validParks.first.longitude,
    );
    final currentSpots = spotsAsync.asData?.value ?? const <SpotModel>[];
    final searchedParks = _applySearch(validParks, currentSpots);
    final parkClusters = _showParks
        ? _clusterParks(_filterVisibleParks(searchedParks))
        : const <_ClusterItem>[];
    final visibleSpotPoints = _filterVisibleSpotPoints(
      _buildSpotPoints(validParks, currentSpots),
    );
    final suggestions = _buildSuggestions(validParks, currentSpots);

    if (_pendingFocusRequest != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (!mounted) {
          return;
        }
        _applyPendingFocus(validParks);
      });
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: _initialZoom,
            minZoom: 3,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
              scrollWheelVelocity: 0.02,
            ),
            onTap: (tapPosition, point) => _dismissSearchOverlay(),
            onMapReady: () {
              _isMapReady = true;
              _syncVisibleBoundsFromController();
              _applyPendingFocus(validParks);
            },
            onPositionChanged: (camera, hasGesture) => _updateCamera(camera),
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: const [],
              additionalOptions: _hasMapTilerKey
                  ? const {'key': _mapTilerApiKey}
                  : const {},
              tileProvider: _tileProvider,
              userAgentPackageName: 'com.potaonthego.app',
            ),
            if (_showParks)
              MarkerLayer(
                markers: parkClusters
                    .map((cluster) => _buildParkMarker(context, cluster))
                    .toList(growable: false),
              ),
            MarkerLayer(
              markers: visibleSpotPoints
                  .map((spotPoint) => _buildSpotMarker(spotPoint))
                  .toList(growable: false),
            ),
          ],
        ),
        SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(12, 12, 12, 10 + viewInsets.bottom),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: TextFieldTapRegion(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchBar(theme),
                        const SizedBox(height: 12),
                        if (_searchFocusNode.hasFocus &&
                            suggestions.isNotEmpty) ...[
                          _buildSuggestionsPanel(theme, suggestions),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!keyboardVisible)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildMapControls(theme),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onTap: _reopenSuggestions,
        onTapOutside: (pointerEvent) => _dismissSearchOverlay(),
        onChanged: (value) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
            setState(() => _searchQuery = value);
          });
        },
        decoration: InputDecoration(
          hintText: 'Park veya çağrı işareti ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: _searchQuery.isEmpty
                ? 'Parkları yenile'
                : 'Aramayı temizle',
            onPressed: () async {
              if (_searchQuery.isEmpty) {
                await _refreshParks();
                return;
              }
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            icon: _searchQuery.isEmpty
                ? RotationTransition(
                    turns: _refreshController,
                    child: Icon(
                      _isRefreshingParks
                          ? Icons.autorenew_rounded
                          : Icons.refresh_rounded,
                    ),
                  )
                : const Icon(Icons.close_rounded),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshParks() async {
    if (_isRefreshingParks) {
      return;
    }

    setState(() => _isRefreshingParks = true);
    _refreshController.repeat();
    try {
      ref.invalidate(localParksProvider);
      await ref.read(localParksProvider.future);
    } finally {
      if (mounted) {
        _refreshController
          ..stop()
          ..reset();
        setState(() => _isRefreshingParks = false);
      }
    }
  }

  void _handleSearchFocusChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _reopenSuggestions() {
    if (_searchFocusNode.hasFocus) {
      setState(() {});
      return;
    }
    _searchFocusNode.requestFocus();
  }

  void _dismissSearchOverlay() {
    FocusScope.of(context).unfocus();
  }

  void _applyPendingFocus(List<ParkModel> parks) {
    final request = _pendingFocusRequest;
    if (request == null || !_isMapReady) {
      return;
    }

    final normalizedReference = request.reference.trim().toUpperCase();

    final park = parks
        .where(
          (park) => park.reference.trim().toUpperCase() == normalizedReference,
        )
        .firstOrNull;
    if (park == null) {
      return;
    }

    _searchController.text = park.reference;
    setState(() => _searchQuery = park.reference);
    _dismissSearchOverlay();
    _focusMapOnPark(park, minimumZoom: 11.5);
    _showMapMessage(
      '${request.activator} haritada ${park.reference} konumuna odaklandi.',
    );

    _pendingFocusRequest = null;
    ref.read(mapFocusRequestProvider.notifier).state = null;
  }

  static String _mapTileKeyGenerator(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return BuiltInMapCachingProvider.uuidTileKeyGenerator(url);
    }

    final sanitizedQueryParameters = Map<String, String>.from(
      uri.queryParameters,
    )..remove('key');
    final sanitizedUrl = uri
        .replace(
          queryParameters: sanitizedQueryParameters.isEmpty
              ? null
              : sanitizedQueryParameters,
        )
        .toString();

    return BuiltInMapCachingProvider.uuidTileKeyGenerator(sanitizedUrl);
  }

  Widget _buildSuggestionsPanel(
    ThemeData theme,
    List<_SearchSuggestion> suggestions,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: suggestions.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              dense: true,
              title: Text(
                suggestion.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                suggestion.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Icon(
                suggestion.icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              trailing: const Icon(Icons.north_east, size: 16),
              onTap: () => _selectSuggestion(suggestion),
            );
          },
        ),
      ),
    );
  }

  List<_SearchSuggestion> _buildSuggestions(
    List<ParkModel> parks,
    List<SpotModel> spots,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.length < 2) {
      return const [];
    }

    final startsWith = <_SearchSuggestion>[];
    final contains = <_SearchSuggestion>[];
    final seenKeys = <String>{};
    final parkByReference = <String, ParkModel>{
      for (final park in parks) park.reference: park,
    };

    for (final park in parks) {
      final ref = park.reference.toLowerCase();
      final name = park.name.toLowerCase();
      final suggestion = _SearchSuggestion.park(park);
      if (ref.startsWith(query) || name.startsWith(query)) {
        if (seenKeys.add(suggestion.key)) {
          startsWith.add(suggestion);
        }
      } else if (ref.contains(query) || name.contains(query)) {
        if (seenKeys.add(suggestion.key)) {
          contains.add(suggestion);
        }
      }
    }

    for (final spot in spots) {
      final activator = spot.activator.trim();
      final normalizedActivator = activator.toLowerCase();
      final park = parkByReference[spot.reference];
      if (park == null || activator.isEmpty) {
        continue;
      }

      final suggestion = _SearchSuggestion.spot(spot: spot, park: park);
      if (seenKeys.contains(suggestion.key)) {
        continue;
      }

      if (normalizedActivator.startsWith(query)) {
        seenKeys.add(suggestion.key);
        startsWith.add(suggestion);
      } else if (normalizedActivator.contains(query)) {
        seenKeys.add(suggestion.key);
        contains.add(suggestion);
      }
    }

    final result = <_SearchSuggestion>[];
    result.addAll(startsWith);
    result.addAll(contains);

    return result.take(8).toList(growable: false);
  }

  void _selectSuggestion(_SearchSuggestion suggestion) {
    _searchController.text = suggestion.queryText;
    setState(() => _searchQuery = suggestion.queryText);
    _dismissSearchOverlay();
    _focusMapOnPark(suggestion.park, minimumZoom: 12.5);
  }

  Widget _buildMapControls(ThemeData theme) {
    Widget buildButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
      bool busy = false,
    }) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Icon(icon),
      );
    }

    final decoration = BoxDecoration(
      color: theme.colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DecoratedBox(
          decoration: decoration,
          child: Column(
            children: [
              buildButton(
                icon: Icons.add,
                tooltip: 'Yakınlaştır',
                onPressed: () => _zoomBy(1),
              ),
              const SizedBox(
                width: 28,
                child: Divider(height: 1, thickness: 1),
              ),
              buildButton(
                icon: Icons.remove,
                tooltip: 'Uzaklaştır',
                onPressed: () => _zoomBy(-1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: decoration,
          child: buildButton(
            icon: Icons.my_location,
            tooltip: 'Konumuma git',
            onPressed: _isLocating ? null : _centerOnUserLocation,
            busy: _isLocating,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: decoration,
          child: buildButton(
            icon: Icons.tune_rounded,
            tooltip: 'Harita filtreleri',
            onPressed: _openFilterSheet,
          ),
        ),
      ],
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Harita Filtreleri',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _showParks,
                        onChanged: (value) {
                          setState(() => _showParks = value);
                          setSheetState(() {});
                        },
                        secondary: Icon(
                          Icons.park_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Parklar'),
                        subtitle: const Text(
                          'Park noktalarını ve kümeleri göster',
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 36, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(title, textAlign: TextAlign.center),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle, textAlign: TextAlign.center),
                ],
                if (actionLabel != null && onPressed != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.refresh),
                    label: Text(actionLabel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _syncVisibleBoundsFromController() {
    _updateCamera(_mapController.camera);
  }

  Future<void> _centerOnUserLocation() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMapMessage('Konum servisi kapalı.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMapMessage('Konum izni verilmedi.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMapMessage(
          'Konum izni kalıcı olarak reddedildi. Sistem ayarlarından açın.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        math.max(_currentZoom, 12.5),
      );
      _updateCamera(_mapController.camera);
    } on LocationServiceDisabledException {
      _showMapMessage('Konum servisi kapalı.');
    } on TimeoutException {
      _showMapMessage('Konum alınamadı, zaman aşımına uğradı.');
    } catch (_) {
      _showMapMessage('Konum alınırken bir hata oluştu.');
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _showMapMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _zoomBy(double delta) {
    final nextZoom = (_currentZoom + delta).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, nextZoom);
    _updateCamera(_mapController.camera);
  }

  void _updateCamera(MapCamera camera) {
    if (!mounted) return;

    final nextBounds = camera.visibleBounds;
    final nextZoom = camera.zoom;
    if (_visibleBounds == nextBounds && _currentZoom == nextZoom) {
      return;
    }

    setState(() {
      _visibleBounds = nextBounds;
      _currentZoom = nextZoom;
    });
  }

  List<ParkModel> _applySearch(List<ParkModel> parks, List<SpotModel> spots) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.length < 2) {
      return parks;
    }

    final matchingReferences = spots
        .where(
          (spot) =>
              spot.reference.toLowerCase().contains(query) ||
              spot.activator.toLowerCase().contains(query),
        )
        .map((spot) => spot.reference)
        .toSet();

    return parks
        .where((park) {
          return park.reference.toLowerCase().contains(query) ||
              park.name.toLowerCase().contains(query) ||
              matchingReferences.contains(park.reference);
        })
        .toList(growable: false);
  }

  List<ParkModel> _filterVisibleParks(List<ParkModel> parks) {
    final bounds = _visibleBounds;
    if (bounds == null) {
      return parks;
    }

    return parks
        .where((park) => bounds.contains(LatLng(park.latitude, park.longitude)))
        .toList(growable: false);
  }

  List<_SpotPoint> _buildSpotPoints(
    List<ParkModel> parks,
    List<SpotModel> spots,
  ) {
    if (spots.isEmpty) {
      return const [];
    }

    final parkByReference = <String, ParkModel>{
      for (final park in parks) park.reference: park,
    };
    final latestByReference = <String, SpotModel>{};
    for (final spot in spots) {
      final existing = latestByReference[spot.reference];
      if (existing == null || existing.spotTime.isBefore(spot.spotTime)) {
        latestByReference[spot.reference] = spot;
      }
    }

    final query = _searchQuery.trim().toLowerCase();
    return latestByReference.values
        .map((spot) {
          final park = parkByReference[spot.reference];
          if (park == null) {
            return null;
          }

          if (query.length >= 2 &&
              !spot.reference.toLowerCase().contains(query) &&
              !park.name.toLowerCase().contains(query) &&
              !spot.activator.toLowerCase().contains(query)) {
            return null;
          }

          return _SpotPoint(
            point: LatLng(park.latitude, park.longitude),
            spot: spot,
            parkName: park.name,
          );
        })
        .whereType<_SpotPoint>()
        .toList(growable: false);
  }

  List<_SpotPoint> _filterVisibleSpotPoints(List<_SpotPoint> spotPoints) {
    final bounds = _visibleBounds;
    if (bounds == null) {
      return spotPoints;
    }

    return spotPoints
        .where((spotPoint) => bounds.contains(spotPoint.point))
        .toList(growable: false);
  }

  List<_ClusterItem> _clusterParks(List<ParkModel> parks) {
    if (parks.isEmpty) {
      return const [];
    }

    if (_currentZoom >= 10.5) {
      return parks.map(_ClusterItem.single).toList(growable: false);
    }

    final bounds = _visibleBounds ?? _boundsFromParks(parks);
    if (bounds == null) {
      return parks.map(_ClusterItem.single).toList(growable: false);
    }

    final targetCount = math.min(
      parks.length,
      _clusterTargetForZoom(_currentZoom),
    );
    final lonSpan = math.max((bounds.east - bounds.west).abs(), 0.0001);
    final latSpan = math.max((bounds.north - bounds.south).abs(), 0.0001);
    final aspectRatio = lonSpan / latSpan;
    final columns = math.max(4, math.sqrt(targetCount * aspectRatio).round());
    final rows = math.max(4, (targetCount / columns).ceil());
    final lonStep = lonSpan / columns;
    final latStep = latSpan / rows;
    final buckets = <String, List<ParkModel>>{};

    for (final park in parks) {
      final column = (((park.longitude - bounds.west) / lonStep).floor()).clamp(
        0,
        columns - 1,
      );
      final row = (((park.latitude - bounds.south) / latStep).floor()).clamp(
        0,
        rows - 1,
      );
      final key = '$row:$column';
      buckets.putIfAbsent(key, () => []).add(park);
    }

    return buckets.values
        .map((parksInBucket) {
          if (parksInBucket.length == 1) {
            return _ClusterItem.single(parksInBucket.first);
          }

          final latitude =
              parksInBucket.fold<double>(
                0,
                (sum, park) => sum + park.latitude,
              ) /
              parksInBucket.length;
          final longitude =
              parksInBucket.fold<double>(
                0,
                (sum, park) => sum + park.longitude,
              ) /
              parksInBucket.length;
          return _ClusterItem(
            center: LatLng(latitude, longitude),
            parks: parksInBucket,
          );
        })
        .toList(growable: false);
  }

  int _clusterTargetForZoom(double zoom) {
    if (zoom < 4) return 48;
    if (zoom < 5) return 80;
    if (zoom < 6) return 120;
    if (zoom < 7) return 180;
    if (zoom < 8) return 260;
    if (zoom < 9) return 360;
    if (zoom < 10.5) return 520;
    return 999999;
  }

  LatLngBounds? _boundsFromParks(List<ParkModel> parks) {
    if (parks.isEmpty) {
      return null;
    }

    var north = parks.first.latitude;
    var south = parks.first.latitude;
    var east = parks.first.longitude;
    var west = parks.first.longitude;
    for (final park in parks.skip(1)) {
      north = math.max(north, park.latitude);
      south = math.min(south, park.latitude);
      east = math.max(east, park.longitude);
      west = math.min(west, park.longitude);
    }

    return LatLngBounds(LatLng(south, west), LatLng(north, east));
  }

  Marker _buildParkMarker(BuildContext context, _ClusterItem cluster) {
    if (!cluster.isCluster) {
      final park = cluster.parks.first;
      return Marker(
        point: cluster.center,
        width: 16,
        height: 16,
        alignment: Alignment.center,
        child: Tooltip(
          message: '${park.reference} - ${park.name}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleParkMarkerTap(context, park),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F9E44),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final size = cluster.parks.length >= 100 ? 38.0 : 34.0;
    return Marker(
      point: cluster.center,
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Tooltip(
        message: '${cluster.parks.length} park',
        child: GestureDetector(
          onTap: () => _focusMapOnCluster(cluster),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2F7F33),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '${cluster.parks.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Marker _buildSpotMarker(_SpotPoint spotPoint) {
    return Marker(
      point: spotPoint.point,
      width: 14,
      height: 14,
      alignment: Alignment.center,
      child: Tooltip(
        message:
            '${spotPoint.spot.reference} - ${spotPoint.parkName} - ${spotPoint.spot.activator}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showMapMessage(
            '${spotPoint.spot.reference} • ${spotPoint.spot.activator} • ${spotPoint.spot.frequency} MHz',
          ),
          child: Center(
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF7A1F1F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleParkMarkerTap(BuildContext context, ParkModel park) {
    if (_currentZoom < 12.5) {
      _focusMapOnPark(park, minimumZoom: 12.5);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ParkDetailScreen(park: park)),
    );
  }

  void _focusMapOnPark(ParkModel park, {required double minimumZoom}) {
    final nextZoom = math.max(_currentZoom, minimumZoom);
    _mapController.move(LatLng(park.latitude, park.longitude), nextZoom);
    _updateCamera(_mapController.camera);
  }

  void _focusMapOnCluster(_ClusterItem cluster) {
    final nextZoom = math.min(_currentZoom + 1.5, 18.0);
    _mapController.move(cluster.center, nextZoom);
    _updateCamera(_mapController.camera);
  }
}

class _ClusterItem {
  const _ClusterItem({required this.center, required this.parks});

  factory _ClusterItem.single(ParkModel park) {
    return _ClusterItem(
      center: LatLng(park.latitude, park.longitude),
      parks: [park],
    );
  }

  final LatLng center;
  final List<ParkModel> parks;

  bool get isCluster => parks.length > 1;
}

class _SpotPoint {
  const _SpotPoint({
    required this.point,
    required this.spot,
    required this.parkName,
  });

  final LatLng point;
  final SpotModel spot;
  final String parkName;
}

class _SearchSuggestion {
  const _SearchSuggestion({
    required this.key,
    required this.queryText,
    required this.title,
    required this.subtitle,
    required this.park,
    required this.icon,
  });

  factory _SearchSuggestion.park(ParkModel park) {
    return _SearchSuggestion(
      key: 'park:${park.reference}',
      queryText: park.reference,
      title: park.reference,
      subtitle: park.name,
      park: park,
      icon: Icons.park_outlined,
    );
  }

  factory _SearchSuggestion.spot({
    required SpotModel spot,
    required ParkModel park,
  }) {
    return _SearchSuggestion(
      key: 'spot:${spot.activator}:${spot.reference}',
      queryText: spot.activator,
      title: spot.activator,
      subtitle: '${park.reference} • ${park.name}',
      park: park,
      icon: Icons.radio_button_checked,
    );
  }

  final String key;
  final String queryText;
  final String title;
  final String subtitle;
  final ParkModel park;
  final IconData icon;
}

extension on Iterable<ParkModel> {
  ParkModel? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
