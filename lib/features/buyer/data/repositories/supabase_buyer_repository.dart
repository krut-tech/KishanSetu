import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/buyer/domain/models/buyer_dashboard_stats.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_response_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/search_produce_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/subscription_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/wishlist_item_model.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

/// Supabase production implementation of [BuyerRepository].
class SupabaseBuyerRepository implements BuyerRepository {
  final SupabaseClient _client;

  SupabaseBuyerRepository(this._client);

  @override
  Future<AppResult<List<ProduceModel>>> getMarketplaceProduce({
    String? searchQuery,
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    try {
      AppLogger.info('Fetching marketplace produce: query=$searchQuery, cat=$category, loc=$location, sort=$sortBy');
      var query = _client
          .from('produce')
          .select('*, farmer_profile:farmer_id(full_name, district, village, state)')
          .eq('status', 'active');

      if (category != null && category.trim().isNotEmpty && category.toLowerCase() != 'all') {
        query = query.ilike('category', '%${category.trim()}%');
      }

      if (location != null && location.trim().isNotEmpty) {
        query = query.ilike('location', '%${location.trim()}%');
      }

      if (minPrice != null && minPrice > 0) {
        query = query.gte('expected_price', minPrice);
      }

      if (maxPrice != null && maxPrice > 0) {
        query = query.lte('expected_price', maxPrice);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = '%${searchQuery.trim()}%';
        query = query.or('name.ilike.$term,category.ilike.$term,location.ilike.$term');
      }

      final response = await switch (sortBy) {
        'price_asc' => query.order('expected_price', ascending: true),
        'price_desc' => query.order('expected_price', ascending: false),
        'quantity_desc' => query.order('quantity', ascending: false),
        _ => query.order('created_at', ascending: false),
      };

      final list = (response as List)
          .map((row) => ProduceModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching marketplace produce', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching marketplace produce: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching marketplace produce', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<ProduceModel>> getProduceDetails(String produceId) async {
    try {
      AppLogger.info('Fetching produce details for id: $produceId');
      final response = await _client
          .from('produce')
          .select('*, farmer_profile:farmer_id(full_name, district, village, state)')
          .eq('id', produceId)
          .single();

      return right(ProduceModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching produce details', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching produce details: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching produce details', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<List<OfferModel>>> getBuyerOffers(
    String buyerId, {
    String? status,
  }) async {
    try {
      AppLogger.info('Fetching offers for buyer: $buyerId, status: $status');
      var query = _client
          .from('offers')
          .select('*, offer_history(*), produce:produce_id(name, unit, category, expected_price, location), farmer_profile:farmer_id(full_name, district)')
          .eq('buyer_id', buyerId);

      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        query = query.eq('status', status.toLowerCase());
      }

      final response = await query.order('created_at', ascending: false);
      final list = (response as List)
          .map((row) => OfferModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching buyer offers', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching buyer offers: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching buyer offers', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<OfferModel>> makeOffer(OfferModel offer) async {
    try {
      AppLogger.info('Submitting offer for produce: ${offer.produceId} by buyer: ${offer.buyerId}');

      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.id != offer.buyerId) {
        return left(const AuthFailure('You are not authorized to submit this offer.'));
      }

      final created = await _client.rpc('create_offer', params: {
        'p_produce_id': offer.produceId,
        'p_offered_price': offer.offeredPrice,
        'p_quantity': offer.quantity,
        'p_message': offer.message,
      }) as Map<String, dynamic>;

      final response = await _client
          .from('offers')
          .select('*, offer_history(*), produce:produce_id(name, unit, category, expected_price, location), farmer_profile:farmer_id(full_name, district)')
          .eq('id', created['id'] as String)
          .single();

      return right(OfferModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error submitting offer', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure submitting offer: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure submitting offer', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<OfferModel>> updateOffer(OfferModel offer) async {
    try {
      AppLogger.info('Updating offer id: ${offer.id} by buyer: ${offer.buyerId}');

      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.id != offer.buyerId) {
        return left(const AuthFailure('You are not authorized to edit this offer.'));
      }

      final response = await _client
          .from('offers')
          .update({
            'offered_price': offer.offeredPrice,
            'quantity': offer.quantity,
            'message': offer.message,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', offer.id)
          .eq('buyer_id', currentUser.id)
          .eq('status', 'pending')
          .select('*, offer_history(*), produce:produce_id(name, unit, category, expected_price, location), farmer_profile:farmer_id(full_name, district)')
          .single();

      return right(OfferModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error updating offer', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure updating offer: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure updating offer', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<OfferModel?>> getExistingOfferForProduce(String buyerId, String produceId) async {
    try {
      AppLogger.info('Checking existing pending offer for buyer: $buyerId, produce: $produceId');
      final response = await _client
          .from('offers')
          .select('*, offer_history(*), produce:produce_id(name, unit, category, expected_price, location), farmer_profile:farmer_id(full_name, district)')
          .eq('produce_id', produceId)
          .eq('buyer_id', buyerId)
          .eq('status', 'pending')
          .maybeSingle();

      if (response == null) {
        return right(null);
      }
      return right(OfferModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error checking existing offer', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure checking existing offer: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure checking existing offer', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<List<OfferHistoryModel>>> getOfferHistory(String offerId) async {
    try {
      AppLogger.info('Fetching offer history for offer: $offerId');
      final response = await _client
          .from('offer_history')
          .select()
          .eq('offer_id', offerId)
          .order('version', ascending: true);

      final list = (response as List)
          .map((row) => OfferHistoryModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching offer history', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching offer history: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching offer history', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<OfferModel>> cancelOffer(String offerId, String buyerId) async {
    try {
      AppLogger.info('Cancelling offer id: $offerId by buyer: $buyerId');
      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.id != buyerId) {
        return left(const AuthFailure('You are not authorized to cancel this offer.'));
      }
      final response = await _client
          .from('offers')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', offerId)
          .eq('buyer_id', buyerId)
          .eq('status', 'pending')
          .select('*, produce:produce_id(name, unit, category, expected_price, location), farmer_profile:farmer_id(full_name, district)')
          .single();

      return right(OfferModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error cancelling offer', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure cancelling offer: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure cancelling offer', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<BuyerDashboardStats>> getBuyerDashboardStats(String buyerId) async {
    try {
      AppLogger.info('Calculating dashboard stats for buyer: $buyerId');

      final produceResponse = await _client
          .from('produce')
          .select('id')
          .eq('status', 'active');

      final produceList = produceResponse as List;
      final totalAvailable = produceList.length;

      final offersResponse = await _client
          .from('offers')
          .select('status')
          .eq('buyer_id', buyerId);

      final offersList = offersResponse as List;
      final totalOffers = offersList.length;
      final pendingOffers = offersList.where((r) => r['status'] == 'pending').length;
      final acceptedOffers = offersList.where((r) => r['status'] == 'accepted').length;

      return right(BuyerDashboardStats(
        totalAvailableProduce: totalAvailable,
        activeOffers: totalOffers,
        pendingOffers: pendingOffers,
        acceptedOffers: acceptedOffers,
      ));
    } on SocketException catch (e) {
      AppLogger.error('Network error calculating buyer stats', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure calculating buyer stats: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure calculating buyer stats', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------
  // Wishlist
  // ---------------------------------------------------------------------

  @override
  Future<AppResult<List<WishlistItemModel>>> getWishlist(String buyerId) async {
    try {
      AppLogger.info('Fetching wishlist for buyer: $buyerId');
      final response = await _client
          .from('wishlists')
          .select('id, created_at, produce:produce_id(*, farmer_profile:farmer_id(full_name, district, village, state))')
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((row) => WishlistItemModel.fromMap(row as Map<String, dynamic>))
          .toList();
      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching wishlist', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching wishlist: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching wishlist', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> addToWishlist({required String buyerId, required String produceId}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.id != buyerId) {
        return left(const AuthFailure('You are not authorized to modify this wishlist.'));
      }
      AppLogger.info('Adding produce $produceId to wishlist for buyer $buyerId');
      await _client.from('wishlists').insert({'buyer_id': buyerId, 'produce_id': produceId});
      return right(null);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Already in wishlist - not an error from the user's point of view.
        return right(null);
      }
      AppLogger.error('Database failure adding to wishlist: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } on SocketException catch (e) {
      AppLogger.error('Network error adding to wishlist', e);
      return left(const NetworkFailure());
    } catch (e, stack) {
      AppLogger.error('Unknown failure adding to wishlist', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> removeFromWishlist(String wishlistId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthFailure('Your session has expired. Please sign in again.'));
      }
      AppLogger.info('Removing wishlist item: $wishlistId');
      await _client.from('wishlists').delete().eq('id', wishlistId).eq('buyer_id', currentUser.id);
      return right(null);
    } on SocketException catch (e) {
      AppLogger.error('Network error removing from wishlist', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure removing from wishlist: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure removing from wishlist', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------
  // RFQ
  // ---------------------------------------------------------------------

  @override
  Future<AppResult<List<RfqModel>>> getMyRfqs(String buyerId) async {
    try {
      AppLogger.info('Fetching RFQs for buyer: $buyerId');
      final response = await _client
          .from('rfqs')
          .select('*, rfq_responses(count)')
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((row) => RfqModel.fromMap(row as Map<String, dynamic>))
          .toList();
      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching RFQs', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching RFQs: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching RFQs', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<RfqModel>> createRfq(RfqModel rfq) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.id != rfq.buyerId) {
        return left(const AuthFailure('You are not authorized to create this RFQ.'));
      }
      AppLogger.info('Creating RFQ for produce: ${rfq.produceName}');
      final response = await _client.from('rfqs').insert(rfq.toMap()).select().single();
      return right(RfqModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error creating RFQ', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure creating RFQ: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure creating RFQ', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> closeRfq(String rfqId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthFailure('Your session has expired. Please sign in again.'));
      }
      await _client
          .from('rfqs')
          .update({'status': 'closed'})
          .eq('id', rfqId)
          .eq('buyer_id', currentUser.id);
      return right(null);
    } on SocketException catch (e) {
      AppLogger.error('Network error closing RFQ', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure closing RFQ: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure closing RFQ', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<List<RfqResponseModel>>> getRfqResponses(String rfqId) async {
    try {
      AppLogger.info('Fetching responses for RFQ: $rfqId');
      final response = await _client
          .from('rfq_responses')
          .select('*, farmer_profile:farmer_id(full_name, district)')
          .eq('rfq_id', rfqId)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((row) => RfqResponseModel.fromMap(row as Map<String, dynamic>))
          .toList();
      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching RFQ responses', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching RFQ responses: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching RFQ responses', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> acceptRfqResponse(String responseId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthFailure('Your session has expired. Please sign in again.'));
      }
      AppLogger.info('Accepting RFQ response: $responseId');
      // RLS's "Buyer accepts or rejects responses on their own RFQ" policy
      // confirms ownership via the parent rfqs row.
      await _client.from('rfq_responses').update({'status': 'accepted'}).eq('id', responseId);
      return right(null);
    } on SocketException catch (e) {
      AppLogger.error('Network error accepting RFQ response', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure accepting RFQ response: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure accepting RFQ response', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> rejectRfqResponse(String responseId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthFailure('Your session has expired. Please sign in again.'));
      }
      AppLogger.info('Rejecting RFQ response: $responseId');
      await _client.from('rfq_responses').update({'status': 'rejected'}).eq('id', responseId);
      return right(null);
    } on SocketException catch (e) {
      AppLogger.error('Network error rejecting RFQ response', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure rejecting RFQ response: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure rejecting RFQ response', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------
  // Advanced search
  // ---------------------------------------------------------------------

  @override
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
  }) async {
    try {
      AppLogger.info('Advanced produce search: query=$query, category=$category, tags=$qualityTags');
      String? fmt(DateTime? d) => d == null
          ? null
          : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final response = await _client.rpc('search_produce', params: {
        'p_query': (query == null || query.trim().isEmpty) ? null : query.trim(),
        'p_category': (category == null || category.trim().isEmpty || category.toLowerCase() == 'all')
            ? null
            : category.trim(),
        'p_quality_tags': (qualityTags == null || qualityTags.isEmpty) ? null : qualityTags,
        'p_harvest_after': fmt(harvestAfter),
        'p_harvest_before': fmt(harvestBefore),
        'p_min_price': minPrice,
        'p_max_price': maxPrice,
        'p_lat': lat,
        'p_lng': lng,
        'p_radius_km': radiusKm,
      });

      final list = (response as List)
          .map((row) => SearchProduceModel.fromMap(row as Map<String, dynamic>))
          .toList();
      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error in advanced search', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure in advanced search: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure in advanced search', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------
  // Subscriptions
  // ---------------------------------------------------------------------

  @override
  Future<AppResult<List<SubscriptionModel>>> getSubscriptions(String buyerId) async {
    try {
      AppLogger.info('Fetching subscriptions for buyer: $buyerId');
      final response = await _client
          .from('subscriptions')
          .select('*, produce:produce_id(name, unit), farmer_profile:farmer_id(full_name)')
          .eq('buyer_id', buyerId)
          .order('next_delivery_date', ascending: true);

      final list = (response as List)
          .map((row) => SubscriptionModel.fromMap(row as Map<String, dynamic>))
          .toList();
      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching subscriptions', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching subscriptions: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching subscriptions', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<SubscriptionModel>> createSubscription(SubscriptionModel subscription) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.id != subscription.buyerId) {
        return left(const AuthFailure('You are not authorized to create this subscription.'));
      }
      AppLogger.info('Creating subscription for produce: ${subscription.produceId}');
      final response = await _client
          .from('subscriptions')
          .insert(subscription.toMap())
          .select('*, produce:produce_id(name, unit), farmer_profile:farmer_id(full_name)')
          .single();
      return right(SubscriptionModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error creating subscription', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure creating subscription: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure creating subscription', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> updateSubscriptionStatus(String subscriptionId, String status) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthFailure('Your session has expired. Please sign in again.'));
      }
      const allowed = {'active', 'paused', 'cancelled'};
      if (!allowed.contains(status)) {
        return left(const DatabaseFailure('Invalid subscription status.'));
      }
      AppLogger.info('Updating subscription $subscriptionId to $status');
      await _client
          .from('subscriptions')
          .update({'status': status})
          .eq('id', subscriptionId)
          .eq('buyer_id', currentUser.id);
      return right(null);
    } on SocketException catch (e) {
      AppLogger.error('Network error updating subscription', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure updating subscription: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure updating subscription', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  RealtimeChannel subscribeToBuyerOffers(
    String buyerId,
    void Function(OfferModel offer) onOfferChange,
  ) {
    AppLogger.info('Setting up Realtime subscription for buyer offers: $buyerId');
    final uniqueId = DateTime.now().microsecondsSinceEpoch;
    final channel = _client.channel('public:offers:buyer_id=${buyerId}_$uniqueId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'offers',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'buyer_id',
        value: buyerId,
      ),
      callback: (payload) {
        AppLogger.info('Realtime buyer offer payload received');
        final record = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
        if (record.isNotEmpty) {
          onOfferChange(OfferModel.fromMap(record));
        }
      },
    ).subscribe();

    return channel;
  }

  @override
  RealtimeChannel subscribeToMarketplaceProduce(
    void Function() onChange,
  ) {
    AppLogger.info('Setting up Realtime subscription for marketplace produce');
    final uniqueId = DateTime.now().microsecondsSinceEpoch;
    final channel = _client.channel('public:produce:marketplace_$uniqueId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'produce',
      callback: (payload) {
        AppLogger.info('Realtime marketplace produce change event received');
        onChange();
      },
    ).subscribe();

    return channel;
  }

  @override
  RealtimeChannel subscribeToProduceDetails(
    String produceId,
    void Function(ProduceModel? produce) onChange,
  ) {
    AppLogger.info('Setting up Realtime subscription for produce details: $produceId');
    final uniqueId = DateTime.now().microsecondsSinceEpoch;
    final channel = _client.channel('public:produce:id=${produceId}_$uniqueId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'produce',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: produceId,
      ),
      callback: (payload) async {
        AppLogger.info('Realtime produce details change payload received for $produceId');
        if (payload.eventType == PostgresChangeEvent.delete) {
          onChange(null);
        } else if (payload.newRecord.isNotEmpty) {
          final updatedRes = await getProduceDetails(produceId);
          updatedRes.fold(
            (_) => onChange(null),
            (updatedProduce) => onChange(updatedProduce),
          );
        }
      },
    ).subscribe();

    return channel;
  }
}
