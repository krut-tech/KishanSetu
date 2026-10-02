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
    default:
      return status.toUpperCase();
  }
}
