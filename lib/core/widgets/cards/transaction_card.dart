import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';

/// Reusable Transaction Card displaying order ID, net payout, and trade stage status.
class TransactionCard extends StatelessWidget {
  final String orderId;
  final String cropName;
  final String tradeDate;
  final double grossAmount;
  final double netPayout;
  final AppStatusType status;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.orderId,
    required this.cropName,
    required this.tradeDate,
    required this.grossAmount,
    required this.netPayout,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #$orderId',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppStatusBadge(type: status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$cropName • $tradeDate',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: colorScheme.outline),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gross Trade Value',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppPriceText(price: grossAmount, unit: ''),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Net Farmer Payout',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppPriceText(
                      price: netPayout,
                      unit: '',
                      isNetRealization: true,
                      priceStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF34D399) : AppColors.netRealizationBadge,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
