import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/hf_conditions_model.dart';
import '../../data/repositories/hf_conditions_repository.dart';

class HfConditionsScreen extends ConsumerStatefulWidget {
  const HfConditionsScreen({super.key});

  @override
  ConsumerState<HfConditionsScreen> createState() => _HfConditionsScreenState();
}

class _HfConditionsScreenState extends ConsumerState<HfConditionsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _refreshController;
  bool _isRefreshing = false;

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

  @override
  Widget build(BuildContext context) {
    final hfConditionsAsync = ref.watch(hfConditionsProvider);

    Future<void> refresh() async {
      if (_isRefreshing) {
        return;
      }

      setState(() => _isRefreshing = true);
      _refreshController.repeat();
      await ref
          .read(hfConditionsRepositoryProvider)
          .getHfConditions(forceRefresh: true);
      ref.invalidate(hfConditionsProvider);
      try {
        await ref.read(hfConditionsProvider.future);
      } finally {
        if (mounted) {
          _refreshController
            ..stop()
            ..reset();
          setState(() => _isRefreshing = false);
        }
      }
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _HfHeader(
                  refreshController: _refreshController,
                  isRefreshing: _isRefreshing,
                  onRefresh: refresh,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              sliver: SliverToBoxAdapter(
                child: hfConditionsAsync.when(
                  data: (snapshot) {
                    if (!snapshot.hasDisplayableData) {
                      return _HfMessageCard(
                        icon: Icons.cloud_off_outlined,
                        message:
                            'HF verisi şu an boş dönüyor. Yenilemeyi deneyin.',
                        actionLabel: 'Yenile',
                        onPressed: () => refresh(),
                      );
                    }

                    return _HfConditionsContent(snapshot: snapshot);
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => _HfMessageCard(
                    icon: Icons.error_outline,
                    message: 'HF koşulları alınamadı: $error',
                    actionLabel: 'Tekrar dene',
                    onPressed: () => refresh(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HfHeader extends StatelessWidget {
  const _HfHeader({
    required this.refreshController,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final Animation<double> refreshController;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'İyonosfer Durumu',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: isRefreshing ? null : () => onRefresh(),
            icon: RotationTransition(
              turns: refreshController,
              child: const Icon(Icons.autorenew_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _HfConditionsContent extends StatelessWidget {
  const _HfConditionsContent({required this.snapshot});

  final HfConditionsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Solar Flux',
        value: snapshot.solarFlux,
        color: const Color(0xFF0EA5E9),
      ),
      _MetricData(
        label: 'A Index',
        value: snapshot.aIndex,
        color: const Color(0xFFF97316),
      ),
      _MetricData(
        label: 'K Index',
        value: snapshot.kIndex,
        color: const Color(0xFF7C3AED),
      ),
      _MetricData(
        label: 'X-Ray',
        value: snapshot.xray,
        color: const Color(0xFFE11D48),
      ),
      _MetricData(
        label: 'Sunspots',
        value: snapshot.sunspots,
        color: const Color(0xFF14B8A6),
      ),
      _MetricData(
        label: 'Signal',
        value: snapshot.signalNoise,
        color: const Color(0xFF059669),
      ),
      _MetricData(
        label: 'MUF',
        value: snapshot.muf,
        color: const Color(0xFF8B5CF6),
      ),
      _MetricData(
        label: 'Solar Wind',
        value: snapshot.solarWind,
        color: const Color(0xFF2563EB),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = constraints.maxWidth >= 360;
            if (!sideBySide) {
              return Column(
                children: [
                  _BandConditionCard(
                    title: 'Gündüz',
                    icon: Icons.light_mode_outlined,
                    accentColor: const Color(0xFFB45309),
                    conditions: snapshot.dayBands,
                  ),
                  const SizedBox(height: 12),
                  _BandConditionCard(
                    title: 'Gece',
                    icon: Icons.dark_mode_outlined,
                    accentColor: const Color(0xFF3730A3),
                    conditions: snapshot.nightBands,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _BandConditionCard(
                    title: 'Gündüz',
                    icon: Icons.light_mode_outlined,
                    accentColor: const Color(0xFFB45309),
                    conditions: snapshot.dayBands,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BandConditionCard(
                    title: 'Gece',
                    icon: Icons.dark_mode_outlined,
                    accentColor: const Color(0xFF3730A3),
                    conditions: snapshot.nightBands,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _MetricPanel(metrics: metrics),
        const SizedBox(height: 10),
        _CompactUpdateCard(snapshot: snapshot),
      ],
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solar Metrikleri',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final columns = maxWidth >= 680
                    ? 4
                    : maxWidth >= 500
                    ? 3
                    : 2;
                final spacing = 10.0;
                final tileWidth =
                    (maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final metric in metrics)
                      SizedBox(
                        width: tileWidth,
                        child: _MetricTile(metric: metric),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = metric.value.isEmpty ? 'N/A' : metric.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            metric.color.withValues(alpha: 0.22),
            metric.color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: metric.color.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              displayValue,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactUpdateCard extends StatelessWidget {
  const _CompactUpdateCard({required this.snapshot});

  final HfConditionsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.update_rounded,
                  size: 17,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Güncelleme',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  snapshot.updated.isEmpty ? 'Bilinmiyor' : snapshot.updated,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Kaynak: ${snapshot.source.isEmpty ? 'N/A' : snapshot.source}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (snapshot.sourceUrl.isNotEmpty)
              Text(
                snapshot.sourceUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BandConditionCard extends StatelessWidget {
  const _BandConditionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.conditions,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final List<HfBandCondition> conditions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (conditions.isEmpty)
              Text(
                'Bu zaman dilimi için veri yok.',
                style: theme.textTheme.bodyMedium,
              )
            else
              ...conditions.map(
                (condition) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BandConditionRow(
                    condition: condition,
                    panelColor: theme.colorScheme.surface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BandConditionRow extends StatelessWidget {
  const _BandConditionRow({required this.condition, required this.panelColor});

  final HfBandCondition condition;
  final Color panelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _ConditionVisual.fromLevel(condition.level, theme);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(visual.icon, size: 16, color: visual.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                condition.bandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  condition.condition,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: visual.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HfMessageCard extends StatelessWidget {
  const _HfMessageCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 36),
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

class _ConditionVisual {
  const _ConditionVisual({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  factory _ConditionVisual.fromLevel(
    HfBandConditionLevel level,
    ThemeData theme,
  ) {
    switch (level) {
      case HfBandConditionLevel.good:
        return _ConditionVisual(
          color: const Color(0xFF1B8F3A),
          icon: Icons.trending_up,
        );
      case HfBandConditionLevel.fair:
        return _ConditionVisual(
          color: const Color(0xFFCC8A00),
          icon: Icons.horizontal_rule_rounded,
        );
      case HfBandConditionLevel.poor:
        return _ConditionVisual(
          color: theme.colorScheme.error,
          icon: Icons.trending_down,
        );
      case HfBandConditionLevel.unknown:
        return _ConditionVisual(
          color: theme.colorScheme.onSurfaceVariant,
          icon: Icons.help_outline,
        );
    }
  }
}
