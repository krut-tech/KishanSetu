import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';

class AppBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Floating frosted-glass bottom navigation. The selected destination expands
/// into a gold (dark) / green (light) pill with its label.
class AppBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppBottomNavItem> items;

  const AppBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pillColor = isDark ? AppColors.accent : AppColors.primary;
    final onPill = isDark ? AppColors.forest : Colors.white;
    final radius = BorderRadius.circular(32);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: isDark ? 0.72 : 0.86),
                borderRadius: radius,
                border: Border.all(color: cs.outline),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      flex: i == selectedIndex ? 3 : 2,
                      child: _NavItem(
                        item: items[i],
                        selected: i == selectedIndex,
                        pillColor: pillColor,
                        onPill: onPill,
                        idleColor: cs.onSurfaceVariant,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onDestinationSelected(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppBottomNavItem item;
  final bool selected;
  final Color pillColor;
  final Color onPill;
  final Color idleColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.selected,
    required this.pillColor,
    required this.onPill,
    required this.idleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? pillColor : Colors.transparent,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    key: ValueKey<bool>(selected),
                    size: 22,
                    color: selected ? onPill : idleColor,
                  ),
                ),
                Flexible(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: onPill,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
