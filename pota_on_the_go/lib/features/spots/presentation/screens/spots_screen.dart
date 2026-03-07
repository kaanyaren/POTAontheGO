import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/providers/nav_bar_metrics_provider.dart';
import '../../../../core/utils/country_utils.dart';
import '../../../../core/utils/radio_utils.dart';
import '../../../home/presentation/providers/home_shell_providers.dart';
import '../../../callsigns/presentation/screens/callsign_info_screen.dart';
import '../../../parks/data/repositories/park_lookup_repository.dart';
import '../../../parks/presentation/providers/park_local_provider.dart';
import '../../data/models/spot_model.dart';
import '../../data/repositories/spot_repository.dart';

const _filterChipRadius = 22.0;
const _compactMenuItemHeight = 34.0;
const _collapsedFilterBarHeight = 66.0;
const _expandedFilterBarHeight = 106.0;
const _unknownModeLabel = 'UNK';
const _allFilterValue = '__all__';

class SpotsScreen extends ConsumerStatefulWidget {
  const SpotsScreen({super.key});

  @override
  ConsumerState<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends ConsumerState<SpotsScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedMode;
  String? _selectedCountry;
  String? _selectedBand;
  late final AnimationController _refreshController;
  bool _isRefreshing = false;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _selectedMode != null ||
      _selectedCountry != null ||
      _selectedBand != null;

  List<String> _buildOptions(
    Iterable<String?> values, {
    int Function(String a, String b)? comparator,
  }) {
    final distinct = <String>{};
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized == null || normalized.isEmpty) {
        continue;
      }
      distinct.add(normalized);
    }

    final sorted = distinct.toList()..sort(comparator);
    return sorted;
  }

  void _clearFilters() {
    setState(() {
      _selectedMode = null;
      _selectedCountry = null;
      _selectedBand = null;
    });
  }

  Future<void> _refreshSpots() async {
    if (_isRefreshing) {
      return;
    }

    setState(() => _isRefreshing = true);
    _refreshController.repeat();
    try {
      await ref.read(spotRepositoryProvider).getRecentSpots(forceRefresh: true);
      ref.invalidate(currentSpotsProvider);
      await ref.read(currentSpotsProvider.future);
    } finally {
      if (mounted) {
        _refreshController
          ..stop()
          ..reset();
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(currentSpotsProvider);
    final parksAsync = ref.watch(localParksProvider);
    final bottomSafePadding = MediaQuery.paddingOf(context).bottom;
    const refreshRightInset = 14.0;
    const refreshButtonSize = 52.0;
    const navBarBottomInset = 14.0;

    final parkNameByReference = {
      for (final park in parksAsync.asData?.value ?? const [])
        park.reference: park.name,
    };

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refreshSpots,
            child: Builder(
              builder: (context) {
                return spotsAsync.when(
                  data: (spots) {
                    final distinctSpots = _dedupeSpots(spots);

                    if (distinctSpots.isEmpty) {
                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                            sliver: const SliverToBoxAdapter(
                              child: _SpotsMessage(
                                icon: Icons.radio_outlined,
                                message: 'Anlık spot verisi bulunamadı.',
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final sortedSpots = [...distinctSpots]
                      ..sort((a, b) => b.spotTime.compareTo(a.spotTime));

                    final modeOptions = _buildOptions(
                      sortedSpots.map((spot) => _normalizedMode(spot.mode)),
                    );
                    final countryOptions = _buildOptions(
                      sortedSpots.map(
                        (spot) => _countryCodeFromReference(spot.reference),
                      ),
                      comparator: (left, right) => countryDisplayName(
                        left,
                      ).compareTo(countryDisplayName(right)),
                    );
                    final bandOptions = _buildOptions(
                      sortedSpots.map(_bandLabelForSpot),
                      comparator: _compareBandLabelsDescending,
                    );

                    final filteredSpots = sortedSpots
                        .where((spot) {
                          final modeMatch =
                              _selectedMode == null ||
                              _normalizedMode(spot.mode) == _selectedMode;
                          final countryMatch =
                              _selectedCountry == null ||
                              _countryCodeFromReference(spot.reference) ==
                                  _selectedCountry;
                          final bandMatch =
                              _selectedBand == null ||
                              _bandLabelForSpot(spot) == _selectedBand;

                          return modeMatch && countryMatch && bandMatch;
                        })
                        .toList(growable: false);

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          sliver: SliverPersistentHeader(
                            pinned: true,
                            delegate: _FilterBarSliverDelegate(
                              child: _SpotsFilterBar(
                                modeOptions: modeOptions,
                                countryOptions: countryOptions,
                                bandOptions: bandOptions,
                                selectedMode: _selectedMode,
                                selectedCountry: _selectedCountry,
                                selectedBand: _selectedBand,
                                resultCount: filteredSpots.length,
                                hasActiveFilters: _hasActiveFilters,
                                isExpanded: _isFilterExpanded,
                                onToggleExpanded: () {
                                  setState(() {
                                    _isFilterExpanded = !_isFilterExpanded;
                                  });
                                },
                                onModeChanged: (value) {
                                  setState(() => _selectedMode = value);
                                },
                                onCountryChanged: (value) {
                                  setState(() => _selectedCountry = value);
                                },
                                onBandChanged: (value) {
                                  setState(() => _selectedBand = value);
                                },
                                onClearFilters: _clearFilters,
                              ),
                              minHeight: _isFilterExpanded
                                  ? _expandedFilterBarHeight
                                  : _collapsedFilterBarHeight,
                              maxHeight: _isFilterExpanded
                                  ? _expandedFilterBarHeight
                                  : _collapsedFilterBarHeight,
                            ),
                          ),
                        ),
                        if (filteredSpots.isEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                            sliver: SliverToBoxAdapter(
                              child: _SpotsMessage(
                                icon: Icons.filter_alt_off,
                                message: 'Filtrelere uygun spot bulunamadı.',
                                actionLabel: _hasActiveFilters
                                    ? 'Filtreleri temizle'
                                    : null,
                                onPressed: _hasActiveFilters
                                    ? _clearFilters
                                    : null,
                                topPadding: 0,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final spot = filteredSpots[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _SpotCard(
                                    spot: spot,
                                    parkName:
                                        parkNameByReference[spot.reference],
                                  ),
                                );
                              }, childCount: filteredSpots.length),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                        sliver: SliverToBoxAdapter(
                          child: const Padding(
                            padding: EdgeInsets.only(top: 36),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  error: (error, _) => CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                        sliver: SliverToBoxAdapter(
                          child: _SpotsMessage(
                            icon: Icons.error_outline,
                            message: 'Spotlar alınamadı: $error',
                            actionLabel: 'Tekrar dene',
                            onPressed: _refreshSpots,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        ValueListenableBuilder<double>(
          valueListenable: bottomNavBarHeightNotifier,
          builder: (context, bottomNavBarHeight, _) {
            final theme = Theme.of(context);
            final navBarHeightWithoutSafe =
                (bottomNavBarHeight - bottomSafePadding).clamp(0.0, 200.0);
            final centeredOffsetWithinNav =
                ((navBarHeightWithoutSafe - refreshButtonSize) / 2).clamp(
                  0.0,
                  200.0,
                );

            return Positioned(
              right: refreshRightInset,
              bottom:
                  bottomSafePadding +
                  navBarBottomInset +
                  centeredOffsetWithinNav,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4E9A52), Color(0xFF2E7F32)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7F32).withValues(alpha: 0.45),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _refreshSpots,
                    child: SizedBox(
                      width: refreshButtonSize,
                      height: refreshButtonSize,
                      child: RotationTransition(
                        turns: _refreshController,
                        child: Icon(
                          Icons.autorenew_rounded,
                          size: 26,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SpotCard extends ConsumerWidget {
  const _SpotCard({required this.spot, required this.parkName});

  final SpotModel spot;
  final String? parkName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final modeLabel = _modeBadgeLabel(spot.mode);
    final resolvedParkName =
        parkName ?? ref.watch(parkNameProvider(spot.reference)).asData?.value;
    final countryCode = _countryCodeFromReference(spot.reference);
    final countryFlag = emojiFlagFromCountryCode(countryCode);
    final bandLabel = _bandLabelForSpot(spot);
    final frequencyLabel = formatFrequencyLabel(spot.frequency);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 50),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          modeLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _openCallsignInfo(context, spot.activator),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              spot.activator,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize:
                                    (theme.textTheme.titleMedium?.fontSize ??
                                        16) +
                                    1,
                                decoration: TextDecoration.underline,
                                decorationColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ),
                        if (frequencyLabel.isNotEmpty ||
                            bandLabel.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (frequencyLabel.isNotEmpty)
                                _SpotTag(
                                  label: '$frequencyLabel MHz',
                                  compact: true,
                                ),
                              if (bandLabel.isNotEmpty)
                                _SpotTag(
                                  label: bandLabel,
                                  compact: true,
                                  toneColor: _bandToneColor(bandLabel, theme),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _parkLabel(resolvedParkName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (countryFlag != null && countryCode != null)
                    _SpotCountryFlag(
                      flag: countryFlag,
                      countryCode: countryCode,
                    ),
                  if (countryFlag != null && countryCode != null)
                    const SizedBox(height: 6),
                  _SpotActionButton(
                    icon: Icons.public_rounded,
                    tooltip: 'Haritada göster',
                    onPressed: () => _openSpotOnMap(context, ref, spot),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _parkLabel(String? resolvedName) {
    final name = resolvedName?.trim();
    if (name == null || name.isEmpty) {
      return spot.reference;
    }
    return '$name • ${spot.reference}';
  }
}

class _SpotsFilterBar extends StatelessWidget {
  const _SpotsFilterBar({
    required this.modeOptions,
    required this.countryOptions,
    required this.bandOptions,
    required this.selectedMode,
    required this.selectedCountry,
    required this.selectedBand,
    required this.resultCount,
    required this.hasActiveFilters,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onModeChanged,
    required this.onCountryChanged,
    required this.onBandChanged,
    required this.onClearFilters,
  });

  final List<String> modeOptions;
  final List<String> countryOptions;
  final List<String> bandOptions;
  final String? selectedMode;
  final String? selectedCountry;
  final String? selectedBand;
  final int resultCount;
  final bool hasActiveFilters;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String?> onModeChanged;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onBandChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultLabel = '$resultCount spot gösteriliyor';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onToggleExpanded,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Filtreler',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  resultLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (hasActiveFilters)
                  IconButton(
                    tooltip: 'Filtreleri temizle',
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                IconButton(
                  tooltip: isExpanded ? 'Filtreleri kapat' : 'Filtreleri aç',
                  onPressed: onToggleExpanded,
                  icon: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _FilterMenuChip(
                      title: 'Mod',
                      allLabel: 'Tüm modlar',
                      options: modeOptions,
                      selectedValue: selectedMode,
                      onSelected: onModeChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterMenuChip(
                      title: 'Ülke',
                      allLabel: 'Tüm ülkeler',
                      options: countryOptions,
                      selectedValue: selectedCountry,
                      onSelected: onCountryChanged,
                      valueLabelBuilder: _countryFilterLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterMenuChip(
                      title: 'Bant',
                      allLabel: 'Tüm bantlar',
                      options: bandOptions,
                      selectedValue: selectedBand,
                      onSelected: onBandChanged,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _countryFilterLabel(String countryCode) {
    final flag = emojiFlagFromCountryCode(countryCode);
    final name = countryDisplayName(countryCode);
    if (flag == null) return name;
    return '$flag $name';
  }
}

class _FilterMenuChip extends StatelessWidget {
  const _FilterMenuChip({
    required this.title,
    required this.allLabel,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.valueLabelBuilder,
  });

  final String title;
  final String allLabel;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;
  final String Function(String value)? valueLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selectedValue != null;
    final displayValue = hasSelection ? _labelForValue(selectedValue!) : title;

    return PopupMenuButton<String>(
      onSelected: (value) {
        onSelected(value == _allFilterValue ? null : value);
      },
      position: PopupMenuPosition.under,
      tooltip: '$title filtresi',
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_filterChipRadius),
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            value: _allFilterValue,
            height: _compactMenuItemHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              allLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ...options.map(
            (option) => PopupMenuItem<String>(
              value: option,
              height: _compactMenuItemHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _labelForValue(option),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ];
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hasSelection
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(_filterChipRadius),
          border: Border.all(
            color: hasSelection
                ? theme.colorScheme.primary.withValues(alpha: 0.38)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasSelection
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: hasSelection
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelForValue(String value) {
    return valueLabelBuilder?.call(value) ?? value;
  }
}

class _FilterBarSliverDelegate extends SliverPersistentHeaderDelegate {
  _FilterBarSliverDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  final Widget child;
  final double minHeight;
  final double maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: Material(color: Colors.transparent, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarSliverDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

class _SpotCountryFlag extends StatelessWidget {
  const _SpotCountryFlag({required this.flag, required this.countryCode});

  final String flag;
  final String countryCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = countryDisplayName(countryCode);

    return Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(_filterChipRadius),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(flag, style: const TextStyle(fontSize: 14, height: 1)),
        ),
      ),
    );
  }
}

class _SpotTag extends StatelessWidget {
  const _SpotTag({required this.label, this.compact = false, this.toneColor});

  final String label;
  final bool compact;
  final Color? toneColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedToneColor = toneColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedToneColor != null
            ? resolvedToneColor.withValues(alpha: 0.16)
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(_filterChipRadius),
        border: Border.all(
          color: resolvedToneColor != null
              ? resolvedToneColor.withValues(alpha: 0.35)
              : theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: resolvedToneColor,
          ),
        ),
      ),
    );
  }
}

class _SpotActionButton extends StatelessWidget {
  const _SpotActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_filterChipRadius),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(_filterChipRadius),
          onTap: onPressed,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

class _SpotsMessage extends StatelessWidget {
  const _SpotsMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onPressed,
    this.topPadding = 36,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              if (actionLabel != null && onPressed != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onPressed, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _normalizedMode(String mode) {
  final upper = mode.trim().toUpperCase();
  if (upper.isEmpty) return _unknownModeLabel;
  if (upper.contains('FT8')) return 'FT8';
  if (upper.contains('FT4')) return 'FT4';
  if (upper.contains('FT')) return 'FT';
  if (upper.contains('CW')) return 'CW';
  if (upper.contains('USB') || upper.contains('LSB')) return 'SSB';
  if (upper.contains('PHONE') || upper.contains('PH')) return 'SSB';
  if (upper.contains('SSB')) return 'SSB';
  if (upper.contains('FM')) return 'FM';
  if (upper.contains('AM')) return 'AM';
  if (upper.contains('RTTY')) return 'RTTY';
  if (upper.contains('PSK')) return 'PSK';
  if (upper.contains('JS8')) return 'JS8';
  if (upper.contains('SSTV')) return 'SSTV';
  if (upper.contains('DIGI') || upper.contains('DIGITAL')) return 'DIGI';
  return upper;
}

String _modeBadgeLabel(String mode) {
  return _normalizedMode(mode);
}

String _bandLabelForSpot(SpotModel spot) {
  return resolveBandLabel(rawBand: spot.band, frequency: spot.frequency);
}

final _isoCountryRegex = RegExp(r'^[A-Z]{2}$');
final _bandMetersRegex = RegExp(r'^(\d+(?:\.\d+)?)(m|cm)$');

String? _countryCodeFromReference(String reference) {
  final trimmed = reference.trim();
  if (trimmed.isEmpty) return null;

  final parts = trimmed.split('-');
  final country = parts.first.trim().toUpperCase();
  if (!_isoCountryRegex.hasMatch(country)) return null;

  return country;
}

List<SpotModel> _dedupeSpots(List<SpotModel> spots) {
  final latestByPrimaryKey = <String, SpotModel>{};
  final latestBySemanticKey = <String, SpotModel>{};
  final latestByActivator = <String, SpotModel>{};

  for (final spot in spots) {
    final primaryKey = spot.spotId > 0
        ? 'spot-id:${spot.spotId}'
        : 'semantic:${_spotSemanticKey(spot)}';
    final existing = latestByPrimaryKey[primaryKey];
    if (existing == null || existing.spotTime.isBefore(spot.spotTime)) {
      latestByPrimaryKey[primaryKey] = spot;
    }
  }

  for (final spot in latestByPrimaryKey.values) {
    final semanticKey = _spotSemanticKey(spot);
    final existing = latestBySemanticKey[semanticKey];
    if (existing == null || existing.spotTime.isBefore(spot.spotTime)) {
      latestBySemanticKey[semanticKey] = spot;
    }
  }

  for (final spot in latestBySemanticKey.values) {
    final callsignKey = spot.activator.trim().toUpperCase();
    final key = callsignKey.isEmpty ? _spotSemanticKey(spot) : callsignKey;
    final existing = latestByActivator[key];
    if (existing == null || existing.spotTime.isBefore(spot.spotTime)) {
      latestByActivator[key] = spot;
    }
  }

  return latestByActivator.values.toList(growable: false);
}

String _spotSemanticKey(SpotModel spot) {
  final frequencyKey = formatFrequencyLabel(spot.frequency);
  return [
    spot.reference.trim().toUpperCase(),
    spot.activator.trim().toUpperCase(),
    frequencyKey.isEmpty ? spot.frequency.trim() : frequencyKey,
    _normalizedMode(spot.mode),
    _bandLabelForSpot(spot).trim().toUpperCase(),
  ].join('|');
}

int _compareBandLabelsDescending(String left, String right) {
  final leftPreferredIndex = _preferredBandOrder.indexOf(left.toLowerCase());
  final rightPreferredIndex = _preferredBandOrder.indexOf(right.toLowerCase());

  final leftPreferred = leftPreferredIndex >= 0;
  final rightPreferred = rightPreferredIndex >= 0;
  if (leftPreferred && rightPreferred) {
    return leftPreferredIndex.compareTo(rightPreferredIndex);
  }
  if (leftPreferred) return -1;
  if (rightPreferred) return 1;

  final leftMeters = _bandMeters(left);
  final rightMeters = _bandMeters(right);

  if (leftMeters != null && rightMeters != null) {
    if (leftMeters == rightMeters) {
      return left.compareTo(right);
    }
    return rightMeters.compareTo(leftMeters);
  }

  if (leftMeters != null) return -1;
  if (rightMeters != null) return 1;
  return left.compareTo(right);
}

const _preferredBandOrder = <String>[
  '80m',
  '60m',
  '40m',
  '30m',
  '20m',
  '17m',
  '15m',
  '12m',
  '10m',
  '6m',
  '4m',
  '2m',
];

double? _bandMeters(String rawBandLabel) {
  final normalized = rawBandLabel.trim().toLowerCase();
  final match = _bandMetersRegex.firstMatch(normalized);
  if (match == null) {
    return null;
  }

  final value = double.tryParse(match.group(1)!);
  final unit = match.group(2);
  if (value == null || unit == null) {
    return null;
  }

  if (unit == 'm') {
    return value;
  }
  if (unit == 'cm') {
    return value / 100;
  }
  return null;
}

Color _bandToneColor(String bandLabel, ThemeData theme) {
  switch (bandLabel.toLowerCase()) {
    case '160m':
      return const Color(0xFF7E57C2);
    case '80m':
      return const Color(0xFFD84315);
    case '60m':
      return const Color(0xFF00897B);
    case '40m':
      return const Color(0xFF1565C0);
    case '30m':
      return const Color(0xFF2E7D32);
    case '20m':
      return const Color(0xFFC2185B);
    case '17m':
      return const Color(0xFF5D4037);
    case '15m':
      return const Color(0xFF6D4C41);
    case '12m':
      return const Color(0xFFEF6C00);
    case '10m':
      return const Color(0xFF00838F);
    case '6m':
      return const Color(0xFF3949AB);
    case '4m':
      return const Color(0xFF6A1B9A);
    case '2m':
      return const Color(0xFF1B8F3A);
    case '1.25m':
      return const Color(0xFF546E7A);
    case '70cm':
      return const Color(0xFFAD1457);
    case '33cm':
      return const Color(0xFF827717);
    case '23cm':
      return const Color(0xFF455A64);
    default:
      return theme.colorScheme.primary;
  }
}

void _openSpotOnMap(BuildContext context, WidgetRef ref, SpotModel spot) {
  FocusScope.of(context).unfocus();
  ref.read(mapFocusRequestProvider.notifier).state = MapFocusRequest(
    reference: spot.reference,
    activator: spot.activator,
  );
  ref.read(homeTabIndexProvider.notifier).state = 0;
}

Future<void> _openCallsignInfo(BuildContext context, String activator) async {
  final callsign = activator.trim().toUpperCase();
  if (callsign.isEmpty) {
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => CallsignInfoScreen(callsign: callsign),
    ),
  );
}
