import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';

class MarketPriceHighlights extends StatelessWidget {
  final List<MarketPriceModel> prices;
  final VoidCallback onViewAll;

  const MarketPriceHighlights({
    super.key,
    required this.prices,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Market Price Highlights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (prices.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  Icons.store_mall_directory_outlined,
                  color: secondaryText,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Market Prices Available',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Market price updates will appear here once published.',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: prices.take(3).map((item) {
              final trendEnum = switch (item.trend.toLowerCase()) {
                'up' => PriceTrend.up,
                'down' => PriceTrend.down,
                'stable' => PriceTrend.stable,
                _ => PriceTrend.none,
              };

              final formattedDate = item.priceDate != null
                  ? DateFormat('dd MMM').format(item.priceDate!)
                  : 'Today';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.produceName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.marketName}${item.location != null ? " • ${item.location}" : ""} ($formattedDate)',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: AppPriceText(
                          price: item.price,
                          unit: item.unit,
                          trend: trendEnum,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
