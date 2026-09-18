import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/features/buyer/domain/models/buyer_dashboard_stats.dart';

/// Stat cards summary for Marketplace and Offers overview on Buyer Dashboard.
class MarketplaceSummaryCards extends StatelessWidget {
  final BuyerDashboardStats stats;
  final ValueChanged<int>? onStatCardTap;

  const MarketplaceSummaryCards({
    super.key,
    required this.stats,
    this.onStatCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Procurement Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                title: 'Available Produce',
                count: stats.totalAvailableProduce,
                icon: Icons.eco_outlined,
                color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
                onTap: () => onStatCardTap?.call(1), // Marketplace tab
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildSummaryCard(
                context,
                title: 'Total Offers',
                count: stats.activeOffers,
                icon: Icons.local_offer_outlined,
                color: isDark ? const Color(0xFF38BDF8) : AppColors.info,
                onTap: () => onStatCardTap?.call(3), // Offers tab
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                title: 'Pending Offers',
                count: stats.pendingOffers,
                icon: Icons.hourglass_top_rounded,
                color: isDark ? const Color(0xFFF59E0B) : AppColors.warning,
                onTap: () => onStatCardTap?.call(3), // Offers tab
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildSummaryCard(
                context,
                title: 'Accepted Offers',
                count: stats.acceptedOffers,
                icon: Icons.check_circle_outline_rounded,
                color: isDark ? const Color(0xFF34D399) : AppColors.success,
                onTap: () => onStatCardTap?.call(3), // Offers tab
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
