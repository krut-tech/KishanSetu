import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/farmer/domain/models/dashboard_stats.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

/// Contract for Farmer feature repository managing produce, market prices, offers, and dashboard stats.
abstract class FarmerRepository {
  /// Fetch produce list for a farmer with optional status filter and search query.
  Future<AppResult<List<ProduceModel>>> getFarmerProduce(
    String farmerId, {
    String? status,
    String? searchQuery,
  });

  /// Add new produce listing.
  Future<AppResult<ProduceModel>> addProduce(ProduceModel produce);

  /// Update existing produce listing.
  Future<AppResult<ProduceModel>> updateProduce(ProduceModel produce);

  /// Delete or archive a produce listing.
  Future<AppResult<void>> deleteProduce(String produceId);

  /// Fetch market prices with search, category, or sorting filter.
  Future<AppResult<List<MarketPriceModel>>> getMarketPrices({
    String? produceName,
    String? category,
    String? marketName,
    String? sortBy, // 'price_asc', 'price_desc', 'date_desc'
  });

  /// Fetch offers received for a farmer's produce.
  Future<AppResult<List<OfferModel>>> getOffersForFarmer(
    String farmerId, {
    String? status,
  });

  /// Accept, reject, or counter an offer.
  Future<AppResult<OfferModel>> updateOfferStatus(String offerId, String status);

  /// Calculate real dashboard statistics for a farmer.
  Future<AppResult<DashboardStats>> getFarmerDashboardStats(String farmerId);

  /// Subscribe to real-time changes on offers for farmer.
  RealtimeChannel subscribeToFarmerOffers(
    String farmerId,
    void Function(OfferModel offer) onNewOffer,
  );

  /// Subscribe to real-time changes on produce for farmer.
  RealtimeChannel subscribeToProduceChanges(
    String farmerId,
    void Function() onChange,
  );
}
