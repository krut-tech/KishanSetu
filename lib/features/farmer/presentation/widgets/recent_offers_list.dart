import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/cards/offer_card.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';

class RecentOffersList extends StatelessWidget {
  final List<OfferModel> offers;
  final VoidCallback onViewAll;
  final Function(OfferModel offer, String status)? onRespond;

  const RecentOffersList({
    super.key,
    required this.offers,
    required this.onViewAll,
    this.onRespond,
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
              'Recent Offers Received',
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
        if (offers.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: secondaryText,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Offers Received Yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Offers from interested buyers will appear here.',
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
            children: offers.take(3).map((offer) {
              final statusBadgeType = switch (offer.status.toLowerCase()) {
                'pending' => AppStatusType.pending,
                'accepted' => AppStatusType.accepted,
                'rejected' => AppStatusType.rejected,
                'in_transit' => AppStatusType.inTransit,
                'completed' => AppStatusType.completed,
                _ => AppStatusType.pending,
              };

              final formattedTime = offer.createdAt != null
                  ? DateFormat('dd MMM, hh:mm a').format(offer.createdAt!)
                  : 'Recent';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: OfferCard(
                  cropName: offer.produceName ?? 'Produce Listing',
                  buyerName: offer.buyerName ?? offer.buyerCompany ?? 'Buyer',
                  offerPrice: offer.offeredPrice,
                  quantity: '${offer.quantity} ${offer.produceUnit ?? "units"}',
                  status: statusBadgeType,
                  expiresText: formattedTime,
                  onAccept: () => onRespond?.call(offer, 'accepted'),
                  onReject: () => onRespond?.call(offer, 'rejected'),
                  onCounter: () => onRespond?.call(offer, 'countered'),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
