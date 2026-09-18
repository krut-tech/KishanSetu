import 'package:equatable/equatable.dart';

/// Dashboard statistics model for Buyer overview.
class BuyerDashboardStats extends Equatable {
  final int totalAvailableProduce;
  final int activeOffers;
  final int acceptedOffers;
  final int pendingOffers;

  const BuyerDashboardStats({
    this.totalAvailableProduce = 0,
    this.activeOffers = 0,
    this.acceptedOffers = 0,
    this.pendingOffers = 0,
  });

  @override
  List<Object?> get props => [
        totalAvailableProduce,
        activeOffers,
        acceptedOffers,
        pendingOffers,
      ];
}
