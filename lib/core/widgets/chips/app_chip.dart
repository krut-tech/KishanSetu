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
    final unselectedBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final unselectedBorder = isDark ? AppColors.borderDark : AppColors.borderLight;
    final unselectedText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : unselectedBg,
          borderRadius: AppRadius.borderPill,
          border: Border.all(
            color: isSelected ? AppColors.primary : unselectedBorder,
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
                color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : unselectedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
