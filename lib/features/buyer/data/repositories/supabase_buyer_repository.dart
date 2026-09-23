import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/buyer/domain/models/buyer_dashboard_stats.dart';
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

      // Validate produce is still active and bind the offer to the listing owner.
      final produceCheck = await _client
          .from('produce')
          .select('status, quantity, farmer_id')
          .eq('id', offer.produceId)
          .maybeSingle();

      if (produceCheck == null) {
        return left(const DatabaseFailure('The requested produce listing no longer exists.'));
      }

      final produceFarmerId = produceCheck['farmer_id'] as String?;
      if (produceFarmerId == null || produceFarmerId != offer.farmerId) {
        return left(const DatabaseFailure('The produce seller does not match this offer.'));
      }

      final duplicate = await _client
          .from('offers')
          .select('id')
          .eq('produce_id', offer.produceId)
          .eq('buyer_id', currentUser.id)
          .or('status.eq.pending,status.eq.countered')
          .limit(1);
      if ((duplicate as List).isNotEmpty) {
        return left(const DatabaseFailure('You already have an active offer for this produce listing. Please edit your existing offer.'));
      }

      final produceStatus = produceCheck['status'] as String?;
      if (produceStatus != 'active') {
        return left(const DatabaseFailure('This produce listing is no longer active for offers.'));
      }

      final availableQty = (produceCheck['quantity'] as num?)?.toDouble() ?? 0.0;
      if (offer.quantity > availableQty) {
        return left(DatabaseFailure('Offered quantity (${offer.quantity}) exceeds available quantity ($availableQty).'));
      }

      final safeOffer = offer.copyWith(buyerId: currentUser.id, farmerId: produceFarmerId);
      final response = await _client
          .from('offers')
          .insert(safeOffer.toMap())
          .select('*, offer_history(*), produce:produce_id(name, unit, category, expected_price, location), farmer_profile:farmer_id(full_name, district)')
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
