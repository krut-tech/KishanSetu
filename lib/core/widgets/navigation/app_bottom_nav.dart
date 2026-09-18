import 'package:flutter/material.dart';
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

/// Reusable bottom navigation bar with smooth destination transitions.
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
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      elevation: 3,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon, color: AppColors.primary),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
