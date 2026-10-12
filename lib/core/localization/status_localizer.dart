import 'package:flutter/widgets.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';

/// Returns the localized display label for an offer status value.
///
/// The raw status strings ('pending', 'accepted', ...) are what the backend
/// stores and what filter logic compares against, so they must NOT be
/// translated in place - only their on-screen label goes through here.
String localizedOfferStatus(BuildContext context, String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return context.l10n.pendingStatus;
    case 'accepted':
      return context.l10n.acceptedStatus;
    case 'rejected':
      return context.l10n.rejectedStatus;
    case 'cancelled':
    case 'canceled':
      return context.l10n.cancelledStatus;
    case 'expired':
      return context.l10n.expiredStatus;
    case 'countered':
      return context.l10n.counteredStatus;
    default:
      return status.toUpperCase();
  }
}

/// Localized display label for produce listing status.
String localizedProduceStatus(BuildContext context, String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return context.l10n.activeStatus;
    case 'draft':
      return context.l10n.draftStatus;
    case 'sold':
      return context.l10n.soldStatus;
    case 'archived':
      return context.l10n.archivedStatus;
    case 'pending':
      return context.l10n.pendingStatus;
    default:
      return status.toUpperCase();
  }
}

/// Localized display label for delivery / order status.
String localizedDeliveryStatus(BuildContext context, String status) {
  switch (status.toLowerCase()) {
    case 'pending_pickup':
      return context.l10n.pendingPickupStatus;
    case 'scheduled':
      return context.l10n.scheduledStatus;
    case 'in_transit':
      return context.l10n.inTransitStatus;
    case 'delivered':
      return context.l10n.deliveredStatus;
    case 'cancelled':
    case 'canceled':
      return context.l10n.cancelledStatus;
    default:
      return status.replaceAll('_', ' ').toUpperCase();
  }
}

/// Localized display label for KYC verification status.
String localizedKycStatus(BuildContext context, String status) {
  switch (status.toLowerCase()) {
    case 'unverified':
      return context.l10n.unverifiedStatus;
    case 'pending':
      return context.l10n.pendingStatus;
    case 'verified':
      return context.l10n.verifiedStatus;
    case 'rejected':
      return context.l10n.rejectedStatus;
    default:
      return status.toUpperCase();
  }
}

/// Localized display label for dispute status.
String localizedDisputeStatus(BuildContext context, String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return context.l10n.openStatus;
    case 'investigating':
      return context.l10n.investigatingStatus;
    case 'resolved':
      return context.l10n.resolvedStatus;
    case 'dismissed':
      return context.l10n.dismissedStatus;
    default:
      return status.toUpperCase();
  }
}

/// General fallback status localizer.
String localizedStatus(BuildContext context, String status) {
  final s = status.toLowerCase();
  if (['pending', 'accepted', 'rejected', 'cancelled', 'canceled', 'expired', 'countered'].contains(s)) {
    return localizedOfferStatus(context, status);
  } else if (['active', 'draft', 'sold', 'archived'].contains(s)) {
    return localizedProduceStatus(context, status);
  } else if (['pending_pickup', 'scheduled', 'in_transit', 'delivered'].contains(s)) {
    return localizedDeliveryStatus(context, status);
  } else if (['unverified', 'verified'].contains(s)) {
    return localizedKycStatus(context, status);
  } else if (['open', 'investigating', 'resolved', 'dismissed'].contains(s)) {
    return localizedDisputeStatus(context, status);
  }
  return status.replaceAll('_', ' ').toUpperCase();
}
