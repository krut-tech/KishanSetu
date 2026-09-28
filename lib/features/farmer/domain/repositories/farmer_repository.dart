import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/farmer/domain/models/crop_calendar_event_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/dashboard_stats.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/nearby_mandi_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/nearby_produce_model.dart';
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

  /// Add many produce listings in a single request (CSV bulk upload).
  Future<AppResult<List<ProduceModel>>> bulkAddProduce(List<ProduceModel> produceList);

  /// Upload a produce photo to storage and return its public URL.
  Future<AppResult<String>> uploadProduceImage({
    required String farmerId,
    required File file,
  });

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

  /// Fetch version history for a specific offer.
  Future<AppResult<List<OfferHistoryModel>>> getOfferHistory(String offerId);

  /// Accept, reject, or counter an offer.
  Future<AppResult<OfferModel>> updateOfferStatus(String offerId, String status);

  /// Calculate real dashboard statistics for a farmer.
  Future<AppResult<DashboardStats>> getFarmerDashboardStats(String farmerId);

  // ---------------------------------------------------------------------
  // Crop calendar
  // ---------------------------------------------------------------------

  Future<AppResult<List<CropCalendarEventModel>>> getCropCalendarEvents(String farmerId);

  Future<AppResult<CropCalendarEventModel>> addCropCalendarEvent(CropCalendarEventModel event);

  Future<AppResult<void>> toggleCropCalendarEventCompleted(String eventId, bool isCompleted);

  Future<AppResult<void>> deleteCropCalendarEvent(String eventId);

  // ---------------------------------------------------------------------
  // Nearby discovery
  // ---------------------------------------------------------------------

  Future<AppResult<List<NearbyProduceModel>>> findNearbyProduce({
    required double lat,
    required double lng,
    double radiusKm = 50,
  });

  Future<AppResult<List<NearbyMandiModel>>> findNearbyMandis({
    required double lat,
    required double lng,
    double radiusKm = 50,
  });

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

  /// Subscribe to real-time changes on market prices.
  RealtimeChannel subscribeToMarketPrices(
    void Function() onChange,
  );
}
