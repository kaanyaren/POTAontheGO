import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/providers/nav_bar_metrics_provider.dart';
import '../providers/home_shell_providers.dart';
import '../../../hf_conditions/presentation/screens/hf_conditions_screen.dart';
import '../../../parks/presentation/screens/map_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../spots/presentation/screens/spots_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final GlobalKey _navBarKey = GlobalKey();
  bool _navBarMeasured = false;

  static const _pages = [
    MapScreen(),
    SpotsScreen(),
    HfConditionsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(homeTabIndexProvider);

    if (!_navBarMeasured) {
      _navBarMeasured = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final box = _navBarKey.currentContext?.findRenderObject() as RenderBox?;
        final height = box?.size.height;
        if (height == null || height == 0) {
          return;
        }
        if (bottomNavBarHeightNotifier.value != height) {
          bottomNavBarHeightNotifier.value = height;
        }
      });
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: selectedIndex, children: _pages),
      bottomNavigationBar: _ShellNavigationBar(
        key: _navBarKey,
        selectedIndex: selectedIndex,
        onSelected: (index) =>
            ref.read(homeTabIndexProvider.notifier).state = index,
      ),
    );
  }
}

class _ShellNavigationBar extends StatelessWidget {
  const _ShellNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = const [
      (icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Harita'),
      (
        icon: Icons.list_alt_outlined,
        activeIcon: Icons.list_alt,
        label: 'Spotlar',
      ),
      (icon: Icons.waves_outlined, activeIcon: Icons.waves, label: 'HF'),
      (
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Ayarlar',
      ),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _ShellNavigationItem(
                    icon: items[index].icon,
                    activeIcon: items[index].activeIcon,
                    label: items[index].label,
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellNavigationItem extends StatelessWidget {
  const _ShellNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
