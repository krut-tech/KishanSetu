import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/buyer/domain/models/buyer_dashboard_stats.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_response_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/search_produce_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/subscription_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/wishlist_item_model.dart';
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

  /// Update an existing pending offer.
  Future<AppResult<OfferModel>> updateOffer(OfferModel offer);

  /// Get active/pending offer for a specific produce listing by buyer.
  Future<AppResult<OfferModel?>> getExistingOfferForProduce(String buyerId, String produceId);

  /// Get version history for a specific offer.
  Future<AppResult<List<OfferHistoryModel>>> getOfferHistory(String offerId);

  /// Cancel a pending offer created by the buyer.
  Future<AppResult<OfferModel>> cancelOffer(String offerId, String buyerId);

  /// Calculate buyer dashboard statistics.
  Future<AppResult<BuyerDashboardStats>> getBuyerDashboardStats(String buyerId);

  // ---------------------------------------------------------------------
  // Wishlist
  // ---------------------------------------------------------------------

  Future<AppResult<List<WishlistItemModel>>> getWishlist(String buyerId);

  Future<AppResult<void>> addToWishlist({required String buyerId, required String produceId});

  Future<AppResult<void>> removeFromWishlist(String wishlistId);

  // ---------------------------------------------------------------------
  // RFQ (Request for Quote) - buyer side
  // ---------------------------------------------------------------------

  Future<AppResult<List<RfqModel>>> getMyRfqs(String buyerId);

  Future<AppResult<RfqModel>> createRfq(RfqModel rfq);

  Future<AppResult<void>> closeRfq(String rfqId);

  Future<AppResult<List<RfqResponseModel>>> getRfqResponses(String rfqId);

  Future<AppResult<void>> acceptRfqResponse(String responseId);

  Future<AppResult<void>> rejectRfqResponse(String responseId);

  // ---------------------------------------------------------------------
  // Advanced search
  // ---------------------------------------------------------------------

  Future<AppResult<List<SearchProduceModel>>> advancedSearchProduce({
    String? query,
    String? category,
    List<String>? qualityTags,
    DateTime? harvestAfter,
    DateTime? harvestBefore,
    double? minPrice,
    double? maxPrice,
    double? lat,
    double? lng,
    double? radiusKm,
  });

  // ---------------------------------------------------------------------
  // Subscriptions / recurring orders
  // ---------------------------------------------------------------------

  Future<AppResult<List<SubscriptionModel>>> getSubscriptions(String buyerId);

  Future<AppResult<SubscriptionModel>> createSubscription(SubscriptionModel subscription);

  Future<AppResult<void>> updateSubscriptionStatus(String subscriptionId, String status);

  /// Subscribe to real-time changes on buyer offers.
  RealtimeChannel subscribeToBuyerOffers(
    String buyerId,
    void Function(OfferModel offer) onOfferChange,
  );

  /// Subscribe to real-time changes on marketplace produce listings.
  RealtimeChannel subscribeToMarketplaceProduce(
    void Function() onChange,
  );

  /// Subscribe to real-time changes on a specific produce listing.
  RealtimeChannel subscribeToProduceDetails(
    String produceId,
    void Function(ProduceModel? produce) onChange,
  );
}
