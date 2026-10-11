import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';

/// Reusable filter and choice chips for crop categories, grades, and mandis.
class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final unselectedBorder =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final unselectedText =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final unselectedIcon =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Selected state follows the theme: gold on dark, green on light.
    final selectedBg = isDark ? AppColors.accent : AppColors.primary;
    final selectedFg = isDark ? AppColors.forest : Colors.white;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          // ~40px tall so chips are comfortable to tap
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: AppRadius.borderPill,
            border: Border.all(
              color: isSelected ? selectedBg : unselectedBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? selectedFg : unselectedIcon,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? selectedFg : unselectedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
