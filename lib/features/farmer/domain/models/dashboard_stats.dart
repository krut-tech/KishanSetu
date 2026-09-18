import 'package:equatable/equatable.dart';

/// Calculated stats model for Farmer Dashboard.
class DashboardStats extends Equatable {
  final int totalProduce;
  final int activeListings;
  final int pendingOffers;
  final int acceptedOffers;
  final int soldProduce;
  final int draftProduce;

  const DashboardStats({
    this.totalProduce = 0,
    this.activeListings = 0,
    this.pendingOffers = 0,
    this.acceptedOffers = 0,
    this.soldProduce = 0,
    this.draftProduce = 0,
  });

  @override
  List<Object?> get props => [
        totalProduce,
        activeListings,
        pendingOffers,
        acceptedOffers,
        soldProduce,
        draftProduce,
      ];
}
