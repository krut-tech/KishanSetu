import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/cards/offer_card.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/localization/status_localizer.dart';

/// Recent offers list widget for the Buyer Dashboard.
class BuyerRecentOffersList extends StatelessWidget {
  final List<OfferModel> offers;
  final VoidCallback? onViewAll;
  final ValueChanged<OfferModel>? onCancelOffer;

  const BuyerRecentOffersList({
    super.key,
    required this.offers,
    this.onViewAll,
    this.onCancelOffer,
  });

  AppStatusType _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppStatusType.accepted;
      case 'rejected':
        return AppStatusType.rejected;
      case 'cancelled':
        return AppStatusType.expired;
      case 'pending':
      default:
        return AppStatusType.pending;
    }
  }

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
              context.l10n.myRecentOffers,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: Text(context.l10n.viewAll),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (offers.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Icon(Icons.local_offer_outlined, size: 40, color: secondaryText),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.noSubmittedOffersYet,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.browseMarketplaceSubmitBids,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offers.take(3).length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final farmerIdDisplay = offer.farmerId.length > 6 ? offer.farmerId.substring(0, 6) : offer.farmerId;
              return OfferCard(
                cropName: offer.produceName ?? context.l10n.produceLabel,
                buyerName: offer.farmerName != null ? '${context.l10n.farmerLabel}: ${offer.farmerName}' : '${context.l10n.farmerLabel} ID: $farmerIdDisplay',
                offerPrice: offer.offeredPrice,
                quantity: '${offer.quantity} ${offer.produceUnit ?? context.l10n.unitsLabel}',
                status: _mapStatus(offer.status),
                expiresText: '${context.l10n.statusLabel}: ${localizedOfferStatus(context, offer.status)}',
                onCancel: offer.status == 'pending' ? () => onCancelOffer?.call(offer) : null,
              );
            },
          ),
      ],
    );
  }
}
