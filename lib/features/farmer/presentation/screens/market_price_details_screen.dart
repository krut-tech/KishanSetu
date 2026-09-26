import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';

/// Full-detail view for a single market price record.
///
/// The list screen only has room to show truncated fields, so this screen
/// exists to show every field on the [MarketPriceModel] without ellipsis.
class MarketPriceDetailsScreen extends StatelessWidget {
  final MarketPriceModel price;

  const MarketPriceDetailsScreen({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final trendEnum = switch (price.trend.toLowerCase()) {
      'up' => PriceTrend.up,
      'down' => PriceTrend.down,
      'stable' => PriceTrend.stable,
      _ => PriceTrend.none,
    };

    final trendLabel = switch (trendEnum) {
      PriceTrend.up => 'Rising',
      PriceTrend.down => 'Falling',
      PriceTrend.stable => 'Stable',
      PriceTrend.none => 'No trend data',
    };

    final formattedPriceDate = price.priceDate != null
        ? DateFormat('dd MMM yyyy (EEEE)').format(price.priceDate!)
        : 'Not specified';

    final formattedUpdatedAt = price.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(price.createdAt!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(price.produceName.isNotEmpty ? price.produceName : 'Market Price Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          price.produceName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (price.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            price.category!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFDCFCE7) : AppColors.primaryDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPriceText(
                    price: price.price,
                    unit: price.unit,
                    trend: trendEnum,
                    priceStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trendLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: switch (trendEnum) {
                        PriceTrend.up => isDark ? const Color(0xFF4ADE80) : AppColors.success,
                        PriceTrend.down => isDark ? const Color(0xFFF87171) : AppColors.error,
                        _ => colorScheme.onSurfaceVariant,
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Market Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  _DetailRow(icon: Icons.storefront_outlined, label: 'Market / Mandi', value: price.marketName),
                  if (price.location != null)
                    _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: price.location!),
                  _DetailRow(icon: Icons.calendar_today_outlined, label: 'Price Date', value: formattedPriceDate),
                  if (price.source != null)
                    _DetailRow(icon: Icons.verified_outlined, label: 'Source', value: price.source!, isLast: formattedUpdatedAt == null),
                  if (formattedUpdatedAt != null)
                    _DetailRow(
                      icon: Icons.history_outlined,
                      label: 'Last Synced',
                      value: formattedUpdatedAt,
                      isLast: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Prices shown are as last reported for this market and may change whenever '
              'updated data is published for this crop.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
      ],
    );
  }
}
