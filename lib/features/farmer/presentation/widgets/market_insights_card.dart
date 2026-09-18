import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';

class MarketInsightsCard extends StatelessWidget {
  final List<MarketPriceModel> marketPrices;

  const MarketInsightsCard({
    super.key,
    required this.marketPrices,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (marketPrices.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Market Price Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No price data available to calculate market analytics.',
              style: TextStyle(
                fontSize: 13,
                color: secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    final prices = marketPrices.map((m) => m.price).toList();
    prices.sort();

    final lowest = prices.first;
    final highest = prices.last;
    final avg = prices.reduce((a, b) => a + b) / prices.length;
    final commonUnit = marketPrices.first.unit;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Market Price Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildInsightColumn(
                  label: 'Highest Price',
                  price: highest,
                  unit: commonUnit,
                  color: isDark ? const Color(0xFF4ADE80) : AppColors.success,
                  secondaryText: secondaryText,
                ),
              ),
              Container(width: 1, height: 40, color: dividerColor),
              Expanded(
                child: _buildInsightColumn(
                  label: 'Average Price',
                  price: avg,
                  unit: commonUnit,
                  color: isDark ? const Color(0xFF6EE7B7) : AppColors.primary,
                  secondaryText: secondaryText,
                ),
              ),
              Container(width: 1, height: 40, color: dividerColor),
              Expanded(
                child: _buildInsightColumn(
                  label: 'Lowest Price',
                  price: lowest,
                  unit: commonUnit,
                  color: isDark ? const Color(0xFFFBBF24) : AppColors.warning,
                  secondaryText: secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightColumn({
    required String label,
    required double price,
    required String unit,
    required Color color,
    required Color secondaryText,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AppPriceText(
            price: price,
            unit: unit,
            priceStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
