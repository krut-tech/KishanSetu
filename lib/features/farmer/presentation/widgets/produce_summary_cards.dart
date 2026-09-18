import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/animations/animated_price_counter.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/features/farmer/domain/models/dashboard_stats.dart';

class ProduceSummaryCards extends StatelessWidget {
  final DashboardStats stats;
  final Function(int tabIndex)? onStatCardTap;

  const ProduceSummaryCards({
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
          'Produce & Offers Summary',
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
              child: _buildStatCard(
                context,
                title: 'Active Listings',
                count: stats.activeListings,
                icon: Icons.eco_rounded,
                iconBg: isDark ? const Color(0xFF064E3B) : AppColors.activeBg,
                iconColor: isDark ? const Color(0xFF34D399) : AppColors.activeFg,
                onTap: () => onStatCardTap?.call(2), // My Produce tab
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Pending Offers',
                count: stats.pendingOffers,
                icon: Icons.local_offer_rounded,
                iconBg: isDark ? const Color(0xFF78350F) : AppColors.pendingBg,
                iconColor: isDark ? const Color(0xFFFBBF24) : AppColors.pendingFg,
                onTap: () => onStatCardTap?.call(3), // Offers tab
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Sold Produce',
                count: stats.soldProduce,
                icon: Icons.check_circle_rounded,
                iconBg: isDark ? const Color(0xFF14532D) : AppColors.acceptedBg,
                iconColor: isDark ? const Color(0xFF4ADE80) : AppColors.acceptedFg,
                onTap: () => onStatCardTap?.call(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Draft Listings',
                count: stats.draftProduce,
                icon: Icons.edit_document,
                iconBg: isDark ? AppColors.borderDark : AppColors.draftBg,
                iconColor: isDark ? AppColors.textSecondaryDark : AppColors.draftFg,
                onTap: () => onStatCardTap?.call(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: AppRadius.borderSm,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedPriceCounter(
                  value: count.toDouble(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
