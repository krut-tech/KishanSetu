import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';

/// Reusable Produce Listing Card displaying crop details, Net Realization, and seller location.
class ProduceCard extends StatelessWidget {
  final String cropName;
  final String grade;
  final String quantity;
  final double askingPrice;
  final double netRealizationPrice;
  final String location;
  final String farmerName;
  final VoidCallback? onTap;

  const ProduceCard({
    super.key,
    required this.cropName,
    required this.grade,
    required this.quantity,
    required this.askingPrice,
    required this.netRealizationPrice,
    required this.location,
    required this.farmerName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(
                  Icons.eco_rounded,
                  color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cropName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Text(
                              grade,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFDCFCE7) : AppColors.primaryDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: secondaryText),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '$location • $farmerName',
                            style: TextStyle(fontSize: 13, color: secondaryText),
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
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quantity,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText),
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
                      'Asking Price',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    AppPriceText(price: askingPrice),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.primaryDark.withValues(alpha: 0.3) : AppColors.netRealizationBg,
              borderRadius: AppRadius.borderSm,
              border: Border.all(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: isDark ? const Color(0xFF34D399) : AppColors.netRealizationBadge,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Net Realization:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: AppPriceText(
                    price: netRealizationPrice,
                    isNetRealization: true,
                    priceStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF34D399) : AppColors.netRealizationBadge,
                    ),
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
