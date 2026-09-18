import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';

/// Reusable Buyer Requirement Card displaying buyer requirements, target price, and company info.
class BuyerRequirementCard extends StatelessWidget {
  final String cropNeeded;
  final String targetQuantity;
  final double targetPrice;
  final String location;
  final String companyName;
  final bool isVerified;
  final VoidCallback? onTap;

  const BuyerRequirementCard({
    super.key,
    required this.cropNeeded,
    required this.targetQuantity,
    required this.targetPrice,
    required this.location,
    required this.companyName,
    this.isVerified = true,
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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(Icons.store_rounded, color: isDark ? const Color(0xFF34D399) : AppColors.secondaryDark, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            companyName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 16, color: AppColors.info),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buying $cropNeeded',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Quantity: $targetQuantity',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Target Price',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppPriceText(price: targetPrice),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
