import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/radio_utils.dart';
import '../../../callsigns/presentation/screens/callsign_info_screen.dart';
import '../../../home/presentation/providers/home_shell_providers.dart';
import '../../data/repositories/park_sync_repository.dart';
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
  static const _fallbackCenter = LatLng(39.0, 35.0);
  // MapTiler key may be supplied via dart-define.  this lets us
  // inject the secret from the file at build time. if none is provided the
  // public fallback key is used.
  static const _defaultMapTilerKey = 'mzn6luuWKoNUsIQaEarr';
  static String get _mapTilerKey => String.fromEnvironment(
    'MAPTILER_API_KEY',
    defaultValue: _defaultMapTilerKey,
  ).trim();
  static String get _mapTilerRasterUrl =>
      'https://api.maptiler.com/maps/openstreetmap/256/{z}/{x}/{y}@2x.png?key=$_mapTilerKey';
  static const _fallbackTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _spotInfoCardControlsOffset = 252.0;
  static const _mapTileErrorThreshold = 8;

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final AnimationController _refreshController;
  late final NetworkTileProvider _tileProvider;

  LatLngBounds? _visibleBounds;
  double _currentZoom = _initialZoom;
  double _currentRotation = 0;
  bool _isLocating = false;
  bool _isRefreshingParks = false;
  bool _isMapReady = false;
  bool _showParks = false;
  bool _forceOsmFallback = false;
  _SpotPoint? _selectedSpotPoint;
  String _searchQuery = '';
  MapFocusRequest? _pendingFocusRequest;
  Timer? _debounceTimer;
  int _mapTileErrorCount = 0;
  DateTime? _lastTileErrorAt;
  int _lookupRequestSerial = 0;
  List<_LookupCallsign> _lookupCallsigns = const [];
  Timer? _cameraThrottle;
  CancelToken? _lookupCancelToken;

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
    _cameraThrottle?.cancel();
    _lookupCancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parksAsync = ref.watch(localParksProvider);
    final spotsAsync = ref.watch(currentSpotsProvider);
    final theme = Theme.of(context);
    final tileUrl = (_mapTilerKey.isNotEmpty && !_forceOsmFallback)
        ? _mapTilerRasterUrl
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
    final currentSpots = spotsAsync.asData?.value ?? const <SpotModel>[];
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
    final hasParkData = validParks.isNotEmpty;

    final initialCenter = hasParkData
        ? LatLng(validParks.first.latitude, validParks.first.longitude)
        : _fallbackCenter;
    final searchedParks = hasParkData
        ? _applySearch(validParks, currentSpots)
        : <ParkModel>[];
    final parkClusters = _showParks
        ? _clusterParks(_filterVisibleParks(searchedParks))
        : const <_ClusterItem>[];
    final visibleSpotPoints = hasParkData
        ? _filterVisibleSpotPoints(_buildSpotPoints(validParks, currentSpots))
        : const <_SpotPoint>[];
    final suggestions = hasParkData
        ? _buildSuggestions(validParks, currentSpots, _lookupCallsigns)
        : const <_SearchSuggestion>[];

    if (_pendingFocusRequest != null && hasParkData) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (!mounted) {
          return;
        }
        _applyPendingFocus(validParks);
      });
    }

    return Stack(
      children: [
        RepaintBoundary(
          child: FlutterMap(
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
              onTap: (tapPosition, point) => _handleMapTap(),
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
                additionalOptions: const {},
                keepBuffer: 4,
                panBuffer: 2,
                maxNativeZoom: 20,
                tileDisplay: const TileDisplay.instantaneous(),
                tileProvider: _tileProvider,
                userAgentPackageName: 'com.example.pota_on_the_go',
                errorTileCallback: _handleTileError,
                evictErrorTileStrategy:
                    EvictErrorTileStrategy.notVisibleRespectMargin,
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
                        if (!hasParkData) ...[
                          const SizedBox(height: 10),
                          _buildNoParkDataBanner(theme),
                        ],
                        const SizedBox(height: 12),
                        if (_searchFocusNode.hasFocus &&
                            suggestions.isNotEmpty) ...[
                          _buildSuggestionsPanel(
                            theme,
                            suggestions,
                            validParks,
                            currentSpots,
                          ),
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
                      padding: EdgeInsets.only(
                        bottom: _selectedSpotPoint != null
                            ? _spotInfoCardControlsOffset
                            : 6,
                      ),
                      child: _buildMapControls(theme),
                    ),
                  ),
                if (!keyboardVisible && _selectedSpotPoint != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildSelectedSpotCard(theme, _selectedSpotPoint!),
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
            unawaited(_fetchLookupCallsigns(value));
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
              setState(() {
                _searchQuery = '';
                _lookupCallsigns = const [];
              });
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
      await ref.read(parkSyncRepositoryProvider).syncParksFromCsv();
      ref.invalidate(localParksProvider);
      final parks = await ref.read(localParksProvider.future);
      if (mounted && parks.isEmpty) {
        _showMapMessage(
          'Park verisi henuz alinamadi. Ag baglantisini kontrol edip tekrar deneyin.',
        );
      }
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

  void _handleMapTap() {
    _dismissSearchOverlay();
    if (_selectedSpotPoint != null) {
      setState(() => _selectedSpotPoint = null);
    }
  }

  void _handleTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    if (_forceOsmFallback || _mapTilerKey.isEmpty) {
      return;
    }

    final now = DateTime.now();
    if (_lastTileErrorAt == null ||
        now.difference(_lastTileErrorAt!) > const Duration(seconds: 8)) {
      _mapTileErrorCount = 0;
    }
    _lastTileErrorAt = now;

    _mapTileErrorCount += 1;
    if (_mapTileErrorCount < _mapTileErrorThreshold || !mounted) {
      return;
    }

    setState(() => _forceOsmFallback = true);
    _showMapMessage(
      'Map katmani yuklenemedi. Harita OpenStreetMap kaynagina gecirildi.',
    );
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

    // If the focus request included an activator, attempt to open its
    // spot card on the map (behaves like tapping the red spot marker).
    final activator = request.activator.trim();
    if (activator.isNotEmpty) {
      final spots =
          ref.read(currentSpotsProvider).asData?.value ?? const <SpotModel>[];
      final normalizedActivator = activator.toUpperCase();
      final latestSpot = spots
          .where(
            (s) =>
                s.activator.trim().toUpperCase() == normalizedActivator &&
                s.reference == park.reference,
          )
          .fold<SpotModel?>(
            null,
            (current, s) =>
                current == null || current.spotTime.isBefore(s.spotTime)
                ? s
                : current,
          );

      if (latestSpot != null) {
        setState(() {
          _selectedSpotPoint = _SpotPoint(
            point: LatLng(park.latitude, park.longitude),
            spot: latestSpot,
            parkName: park.name,
          );
        });
      }
    }

    _showMapMessage(
      '${request.activator} haritada ${park.reference} konumuna odaklandı.',
    );

    _pendingFocusRequest = null;
    ref.read(mapFocusRequestProvider.notifier).state = null;
  }

  static String _mapTileKeyGenerator(String url) {
    // Keep the full URL in the cache key so tile caches do not mix between
    // different MapTiler API keys.
    return BuiltInMapCachingProvider.uuidTileKeyGenerator(url);
  }

  Widget _buildNoParkDataBanner(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Park verisi bulunamadi. Harita acik, veriyi tekrar indirebilirsiniz.',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(onPressed: _refreshParks, child: const Text('Yenile')),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsPanel(
    ThemeData theme,
    List<_SearchSuggestion> suggestions,
    List<ParkModel> parks,
    List<SpotModel> spots,
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
              onTap: () => _selectSuggestion(suggestion, parks, spots),
            );
          },
        ),
      ),
    );
  }

  List<_SearchSuggestion> _buildSuggestions(
    List<ParkModel> parks,
    List<SpotModel> spots,
    List<_LookupCallsign> lookupCallsigns,
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

    for (final lookup in lookupCallsigns) {
      final suggestion = _SearchSuggestion.lookup(lookup);
      if (seenKeys.contains(suggestion.key)) {
        continue;
      }

      if (lookup.callsign.toLowerCase().startsWith(query)) {
        seenKeys.add(suggestion.key);
        startsWith.add(suggestion);
      } else if (lookup.callsign.toLowerCase().contains(query)) {
        seenKeys.add(suggestion.key);
        contains.add(suggestion);
      }
    }

    final result = <_SearchSuggestion>[];
    result.addAll(startsWith);
    result.addAll(contains);

    return result.take(8).toList(growable: false);
  }

  void _selectSuggestion(
    _SearchSuggestion suggestion,
    List<ParkModel> parks,
    List<SpotModel> spots,
  ) {
    _searchController.text = suggestion.queryText;
    setState(() => _searchQuery = suggestion.queryText);
    _dismissSearchOverlay();

    final selectedPark = suggestion.park;
    if (selectedPark != null) {
      _focusMapOnPark(selectedPark, minimumZoom: 12.5);
      return;
    }

    final activator = suggestion.activator;
    if (activator == null || activator.isEmpty) {
      return;
    }

    final normalizedActivator = activator.trim().toUpperCase();
    final latestSpot = spots
        .where(
          (spot) => spot.activator.trim().toUpperCase() == normalizedActivator,
        )
        .fold<SpotModel?>(
          null,
          (current, spot) =>
              current == null || current.spotTime.isBefore(spot.spotTime)
              ? spot
              : current,
        );

    if (latestSpot == null) {
      _openCallsignInfo(activator);
      return;
    }

    final parkByReference = <String, ParkModel>{
      for (final park in parks) park.reference: park,
    };
    final matchedPark = parkByReference[latestSpot.reference];
    if (matchedPark == null) {
      _showMapMessage('$activator için harita konumu bulunamadı.');
      return;
    }

    _focusMapOnPark(matchedPark, minimumZoom: 12.5);
    _showMapMessage(
      '$activator için son aktif nokta ${latestSpot.reference} üzerinde gösterildi.',
    );
  }

  Future<void> _fetchLookupCallsigns(String rawQuery) async {
    final query = rawQuery.trim();
    final requestSerial = ++_lookupRequestSerial;
    if (query.length < 2) {
      if (!mounted) return;
      setState(() => _lookupCallsigns = const []);
      return;
    }

    _lookupCancelToken?.cancel();
    _lookupCancelToken = CancelToken();
    try {
      final response = await DioClient().dio.get(
        'lookup',
        queryParameters: {'search': query, 'size': '10'},
        cancelToken: _lookupCancelToken,
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );

      if (!mounted || requestSerial != _lookupRequestSerial) return;

      if (response.statusCode != 200 || response.data == null) {
        setState(() => _lookupCallsigns = const []);
        return;
      }

      final parsed = _parseLookupCallsigns(response.data);
      setState(() => _lookupCallsigns = parsed);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (!mounted || requestSerial != _lookupRequestSerial) return;
      setState(() => _lookupCallsigns = const []);
    } catch (_) {
      if (!mounted || requestSerial != _lookupRequestSerial) return;
      setState(() => _lookupCallsigns = const []);
    }
  }

  List<_LookupCallsign> _parseLookupCallsigns(dynamic payload) {
    if (payload is! List) {
      return const [];
    }

    final seen = <String>{};
    final result = <_LookupCallsign>[];
    for (final item in payload) {
      if (item is! Map) continue;

      final type = item['type']?.toString().trim().toLowerCase() ?? '';
      if (type.isNotEmpty && type != 'user') continue;

      final value = item['value']?.toString().trim() ?? '';
      final display = item['display']?.toString().trim() ?? '';
      if (value.isEmpty) continue;

      final callsign = value.toUpperCase();
      if (!seen.add(callsign)) continue;
      result.add(_LookupCallsign(callsign: callsign, display: display));
    }

    return result;
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
          child: IconButton(
            tooltip: 'Kuzeyi yukari al',
            onPressed: _currentRotation.abs() < 0.5 ? null : _resetNorth,
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.navigation,
                  size: 16,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(height: 2),
                Text(
                  'N',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
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

  Future<void> _openCallsignInfo(String activator) async {
    final callsign = activator.trim().toUpperCase();
    if (callsign.isEmpty || !mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CallsignInfoScreen(callsign: callsign),
      ),
    );
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
    final nextRotation = camera.rotation;
    if (_visibleBounds == nextBounds &&
        _currentZoom == nextZoom &&
        _currentRotation == nextRotation) {
      return;
    }

    // Store values immediately so programmatic queries (_zoomBy, _resetNorth)
    // see the latest camera state without waiting for a timer.
    _visibleBounds = nextBounds;
    _currentZoom = nextZoom;
    _currentRotation = nextRotation;

    // Throttle widget rebuilds to avoid re-computing clusters, markers,
    // and suggestion lists on every single camera tick.
    if (_cameraThrottle?.isActive ?? false) return;
    _cameraThrottle = Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() {});
    });
  }

  void _resetNorth() {
    if (_currentRotation.abs() < 0.5) {
      return;
    }

    _mapController.moveAndRotate(_mapController.camera.center, _currentZoom, 0);
    _updateCamera(_mapController.camera);
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
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Tooltip(
          message: '${park.reference} - ${park.name}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleParkMarkerTap(context, park),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
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

    final size = cluster.parks.length >= 100 ? 57.0 : 51.0;
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
                fontSize: 14,
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
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: Tooltip(
        message:
            '${spotPoint.spot.reference} - ${spotPoint.parkName} - ${spotPoint.spot.activator}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _dismissSearchOverlay();
            setState(() => _selectedSpotPoint = spotPoint);
          },
          child: Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF7A1F1F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
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

  Widget _buildSelectedSpotCard(ThemeData theme, _SpotPoint spotPoint) {
    final spot = spotPoint.spot;
    final activator = spot.activator.trim();
    final frequency = formatFrequencyLabel(spot.frequency);
    final band = resolveBandLabel(
      rawBand: spot.band,
      frequency: spot.frequency,
    );
    final frequencyAndBand = [
      if (frequency.isNotEmpty) '$frequency MHz',
      if (band.isNotEmpty) band,
    ].join(' • ');

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D4B2F), Color(0xFF153922)],
          ),
          border: Border.all(color: const Color(0xFF3C6C4C), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activator.isNotEmpty)
                InkWell(
                  onTap: () => _openCallsignInfo(activator),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      activator,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                )
              else
                Text(
                  '-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                  ),
                ),
              if (frequencyAndBand.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  frequencyAndBand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFE8F4EB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                '${spotPoint.parkName} • ${spot.reference}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFD6E8DA),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    this.activator,
    required this.icon,
  });

  factory _SearchSuggestion.park(ParkModel park) {
    return _SearchSuggestion(
      key: 'park:${park.reference}',
      queryText: park.reference,
      title: park.reference,
      subtitle: park.name,
      park: park,
      activator: null,
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
      activator: spot.activator,
      icon: Icons.radio_button_checked,
    );
  }

  factory _SearchSuggestion.lookup(_LookupCallsign lookup) {
    return _SearchSuggestion(
      key: 'lookup:${lookup.callsign}',
      queryText: lookup.callsign,
      title: lookup.callsign,
      subtitle: lookup.display,
      park: null,
      activator: lookup.callsign,
      icon: Icons.person_search_rounded,
    );
  }

  final String key;
  final String queryText;
  final String title;
  final String subtitle;
  final ParkModel? park;
  final String? activator;
  final IconData icon;
}

class _LookupCallsign {
  const _LookupCallsign({required this.callsign, required this.display});

  final String callsign;
  final String display;
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
