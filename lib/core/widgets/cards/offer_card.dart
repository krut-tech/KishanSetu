import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';

/// Reusable Offer / Negotiation Card displaying offer status, bid price, and action triggers.
class OfferCard extends StatelessWidget {
  final String cropName;
  final String buyerName;
  final double offerPrice;
  final String quantity;
  final AppStatusType status;
  final String expiresText;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCounter;
  final VoidCallback? onCancel;
  final String? cancelLabel;

  const OfferCard({
    super.key,
    required this.cropName,
    required this.buyerName,
    required this.offerPrice,
    required this.quantity,
    required this.status,
    required this.expiresText,
    this.onAccept,
    this.onReject,
    this.onCounter,
    this.onCancel,
    this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final warningColor = isDark ? const Color(0xFFFBBF24) : AppColors.warning;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              AppStatusBadge(type: status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Offered by $buyerName • Quantity: $quantity',
            style: TextStyle(fontSize: 13, color: secondaryText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offered Price',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    AppPriceText(price: offerPrice),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: warningColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        expiresText,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: warningColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status == AppStatusType.pending) ...[
            const SizedBox(height: AppSpacing.md),
            if (onCancel != null) ...[
              AppButton(
                label: cancelLabel ?? 'Cancel Offer',
                style: AppButtonStyle.outlined,
                onPressed: onCancel,
              ),
            ] else if (onAccept != null || onReject != null || onCounter != null) ...[
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Reject',
                      style: AppButtonStyle.outlined,
                      onPressed: onReject,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Counter',
                      style: AppButtonStyle.secondary,
                      onPressed: onCounter,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Accept',
                      style: AppButtonStyle.primary,
                      onPressed: onAccept,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
