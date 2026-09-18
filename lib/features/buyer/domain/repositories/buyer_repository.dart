import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/buyer/domain/models/buyer_dashboard_stats.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

/// Contract for Buyer feature repository managing marketplace listings, offers, and buyer dashboard data.
abstract class BuyerRepository {
  /// Fetch active marketplace produce listings with filtering and sorting.
  Future<AppResult<List<ProduceModel>>> getMarketplaceProduce({
    String? searchQuery,
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? sortBy, // 'newest', 'price_asc', 'price_desc', 'quantity_desc'
  });

  /// Get details for a specific produce listing.
  Future<AppResult<ProduceModel>> getProduceDetails(String produceId);

  /// Fetch offers submitted by a specific buyer.
  Future<AppResult<List<OfferModel>>> getBuyerOffers(
    String buyerId, {
    String? status,
  });

  /// Submit a new price offer to a farmer.
  Future<AppResult<OfferModel>> makeOffer(OfferModel offer);

  /// Cancel a pending offer created by the buyer.
  Future<AppResult<OfferModel>> cancelOffer(String offerId, String buyerId);

  /// Calculate buyer dashboard statistics.
  Future<AppResult<BuyerDashboardStats>> getBuyerDashboardStats(String buyerId);

  /// Subscribe to real-time changes on buyer offers.
  RealtimeChannel subscribeToBuyerOffers(
    String buyerId,
    void Function(OfferModel offer) onOfferChange,
  );
}
