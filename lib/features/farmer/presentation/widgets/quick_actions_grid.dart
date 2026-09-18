import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/animations/animated_pressable.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onAddProduce;
  final VoidCallback onMyProduce;
  final VoidCallback onMarketPrices;
  final VoidCallback onMyOffers;

  const QuickActionsGrid({
    super.key,
    required this.onAddProduce,
    required this.onMyProduce,
    required this.onMarketPrices,
    required this.onMyOffers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Add Produce',
                icon: Icons.add_circle_outline_rounded,
                bgColor: AppColors.primary,
                fgColor: Colors.white,
                onTap: onAddProduce,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildActionButton(
                label: 'My Produce',
                icon: Icons.inventory_2_outlined,
                bgColor: isDark ? const Color(0xFF14532D) : AppColors.primaryLight,
                fgColor: isDark ? const Color(0xFFDCFCE7) : AppColors.primaryDark,
                onTap: onMyProduce,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Market Prices',
                icon: Icons.trending_up_rounded,
                bgColor: isDark ? const Color(0xFF78350F) : AppColors.secondaryLight,
                fgColor: isDark ? const Color(0xFFFEF3C7) : AppColors.secondaryDark,
                onTap: onMarketPrices,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildActionButton(
                label: 'My Offers',
                icon: Icons.local_offer_outlined,
                bgColor: isDark ? const Color(0xFF0C4A6E) : AppColors.inTransitBg,
                fgColor: isDark ? const Color(0xFFE0F2FE) : AppColors.inTransitFg,
                onTap: onMyOffers,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.borderMd,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fgColor, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
