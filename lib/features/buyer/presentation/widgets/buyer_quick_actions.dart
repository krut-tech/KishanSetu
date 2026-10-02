import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';

/// Quick action grid cards for the Buyer Dashboard.
class BuyerQuickActionsGrid extends StatelessWidget {
  final VoidCallback onBrowseMarketplace;
  final VoidCallback onMarketPrices;
  final VoidCallback onMyOffers;
  final VoidCallback onProfile;
  final VoidCallback onWishlist;
  final VoidCallback onPostRfq;
  final VoidCallback onAdvancedSearch;
  final VoidCallback onSubscriptions;

  const BuyerQuickActionsGrid({
    super.key,
    required this.onBrowseMarketplace,
    required this.onMarketPrices,
    required this.onMyOffers,
    required this.onProfile,
    required this.onWishlist,
    required this.onPostRfq,
    required this.onAdvancedSearch,
    required this.onSubscriptions,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.2,
          children: [
            _buildActionCard(
              context,
              title: 'Marketplace',
              subtitle: 'Browse & Buy',
              icon: Icons.storefront_outlined,
              color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
              onTap: onBrowseMarketplace,
            ),
            _buildActionCard(
              context,
              title: 'Market Prices',
              subtitle: 'Mandi Rates',
              icon: Icons.trending_up_outlined,
              color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
              onTap: onMarketPrices,
            ),
            _buildActionCard(
              context,
              title: 'My Offers',
              subtitle: 'Track Bids',
              icon: Icons.local_offer_outlined,
              color: isDark ? const Color(0xFFF59E0B) : AppColors.warning,
              onTap: onMyOffers,
            ),
            _buildActionCard(
              context,
              title: 'Wishlist',
              subtitle: 'Saved Items',
              icon: Icons.favorite_border_rounded,
              color: Colors.redAccent,
              onTap: onWishlist,
            ),
            _buildActionCard(
              context,
              title: 'Post RFQ',
              subtitle: 'Bulk Request',
              icon: Icons.request_quote_outlined,
              color: isDark ? const Color(0xFF38BDF8) : AppColors.info,
              onTap: onPostRfq,
            ),
            _buildActionCard(
              context,
              title: 'Advanced Search',
              subtitle: 'Filter Produce',
              icon: Icons.tune_rounded,
              color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
              onTap: onAdvancedSearch,
            ),
            _buildActionCard(
              context,
              title: 'Subscriptions',
              subtitle: 'Recurring Orders',
              icon: Icons.autorenew_rounded,
              color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
              onTap: onSubscriptions,
            ),
            _buildActionCard(
              context,
              title: 'My Profile',
              subtitle: 'Company Info',
              icon: Icons.person_outline_rounded,
              color: isDark ? const Color(0xFF38BDF8) : AppColors.info,
              onTap: onProfile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryText,
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
