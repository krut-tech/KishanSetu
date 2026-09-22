import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/farmer/domain/models/dashboard_stats.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';

/// Supabase production implementation of [FarmerRepository].
class SupabaseFarmerRepository implements FarmerRepository {
  final SupabaseClient _client;

  SupabaseFarmerRepository(this._client);

  @override
  Future<AppResult<List<ProduceModel>>> getFarmerProduce(
    String farmerId, {
    String? status,
    String? searchQuery,
  }) async {
    try {
      AppLogger.info('Fetching produce for farmer: $farmerId, status: $status, search: $searchQuery');
      var query = _client.from('produce').select().eq('farmer_id', farmerId);

      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        query = query.eq('status', status.toLowerCase());
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = '%${searchQuery.trim()}%';
        query = query.or('name.ilike.$term,category.ilike.$term,location.ilike.$term');
      }

      final response = await query.order('created_at', ascending: false);
      final list = (response as List)
          .map((row) => ProduceModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching farmer produce', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching produce: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching produce', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<ProduceModel>> addProduce(ProduceModel produce) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.id != produce.farmerId) {
        return left(const AuthFailure('You are not authorized to create this produce listing.'));
      }
      AppLogger.info('Adding new produce: ${produce.name} for farmer: ${produce.farmerId}');
      final response = await _client
          .from('produce')
          .insert(produce.toMap())
          .select()
          .single();

      final created = ProduceModel.fromMap(response);
      return right(created);
    } on SocketException catch (e) {
      AppLogger.error('Network error adding produce', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure adding produce: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure adding produce', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<ProduceModel>> updateProduce(ProduceModel produce) async {
    try {
      AppLogger.info('Updating produce id: ${produce.id}');
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthFailure('Your session has expired. Please sign in again.'));
      }
      final response = await _client
          .from('produce')
          .update(produce.toMap())
          .eq('id', produce.id)
          .eq('farmer_id', currentUser.id)
          .select()
          .single();

      return right(ProduceModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error updating produce', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure updating produce: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure updating produce', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> deleteProduce(String produceId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthFailure('Your session has expired. Please sign in again.'));
      }
      AppLogger.info('Deleting produce id: $produceId');
      await _client
          .from('produce')
          .delete()
          .eq('id', produceId)
          .eq('farmer_id', currentUser.id);
      return right(null);
    } on SocketException catch (e) {
      AppLogger.error('Network error deleting produce', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure deleting produce: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure deleting produce', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<List<MarketPriceModel>>> getMarketPrices({
    String? produceName,
    String? category,
    String? marketName,
    String? sortBy,
  }) async {
    try {
      AppLogger.info('Fetching market prices: produce=$produceName, market=$marketName, sort=$sortBy');
      var query = _client.from('market_prices').select();

      if (produceName != null && produceName.trim().isNotEmpty) {
        query = query.ilike('produce_name', '%${produceName.trim()}%');
      }

      if (category != null && category.trim().isNotEmpty && category.toLowerCase() != 'all') {
        query = query.ilike('category', '%${category.trim()}%');
      }

      if (marketName != null && marketName.trim().isNotEmpty) {
        query = query.ilike('market_name', '%${marketName.trim()}%');
      }

      final response = switch (sortBy) {
        'price_asc' => await query.order('price', ascending: true),
        'price_desc' => await query.order('price', ascending: false),
        _ => await query.order('price_date', ascending: false),
      };

      final list = (response as List)
          .map((row) => MarketPriceModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching market prices', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching market prices: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching market prices', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<List<OfferModel>>> getOffersForFarmer(
    String farmerId, {
    String? status,
  }) async {
    try {
      AppLogger.info('Fetching offers for farmer: $farmerId, status: $status');
      var query = _client
          .from('offers')
          .select('*, offer_history(*), produce:produce_id(name, unit), buyer_profile:buyer_id(full_name, company_name)')
          .eq('farmer_id', farmerId);

      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        query = query.eq('status', status.toLowerCase());
      }

      final response = await query.order('created_at', ascending: false);
      final list = (response as List)
          .map((row) => OfferModel.fromMap(row as Map<String, dynamic>))
          .toList();

      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching offers', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching offers: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching offers', e, stack);
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
  Future<AppResult<OfferModel>> updateOfferStatus(String offerId, String status) async {
    try {
      AppLogger.info('Updating offer status id: $offerId to $status');
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthFailure('Your session has expired. Please sign in again.'));
      }
      const allowedStatuses = {'accepted', 'rejected', 'countered'};
      final normalizedStatus = status.toLowerCase();
      if (!allowedStatuses.contains(normalizedStatus)) {
        return left(const DatabaseFailure('Invalid offer status transition.'));
      }
      final response = await _client
          .from('offers')
          .update({
            'status': normalizedStatus,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', offerId)
          .eq('farmer_id', currentUser.id)
          .eq('status', 'pending')
          .select('*, produce:produce_id(name, unit), buyer_profile:buyer_id(full_name, company_name)')
          .single();

      return right(OfferModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error updating offer status', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure updating offer status: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure updating offer status', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<DashboardStats>> getFarmerDashboardStats(String farmerId) async {
    try {
      AppLogger.info('Calculating dashboard stats for farmer: $farmerId');
      final produceResponse = await _client
          .from('produce')
          .select('status')
          .eq('farmer_id', farmerId);

      final produceList = produceResponse as List;
      int totalProduce = produceList.length;
      int activeListings = produceList.where((r) => r['status'] == 'active').length;
      int soldProduce = produceList.where((r) => r['status'] == 'sold').length;
      int draftProduce = produceList.where((r) => r['status'] == 'draft').length;

      final offersResponse = await _client
          .from('offers')
          .select('status')
          .eq('farmer_id', farmerId);

      final offersList = offersResponse as List;
      int pendingOffers = offersList.where((r) => r['status'] == 'pending').length;
      int acceptedOffers = offersList.where((r) => r['status'] == 'accepted').length;

      return right(DashboardStats(
        totalProduce: totalProduce,
        activeListings: activeListings,
        pendingOffers: pendingOffers,
        acceptedOffers: acceptedOffers,
        soldProduce: soldProduce,
        draftProduce: draftProduce,
      ));
    } on SocketException catch (e) {
      AppLogger.error('Network error calculating stats', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure calculating stats: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure calculating stats', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  RealtimeChannel subscribeToFarmerOffers(
    String farmerId,
    void Function(OfferModel offer) onNewOffer,
  ) {
    AppLogger.info('Setting up Realtime subscription for farmer offers: $farmerId');
    final channel = _client.channel('public:offers:farmer_id=$farmerId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'offers',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'farmer_id',
        value: farmerId,
      ),
      callback: (payload) {
        AppLogger.info('Realtime offer event payload received for farmer');
        final record = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
        if (record.isNotEmpty) {
          onNewOffer(OfferModel.fromMap(record));
        }
      },
    ).subscribe();

    return channel;
  }

  @override
  RealtimeChannel subscribeToProduceChanges(
    String farmerId,
    void Function() onChange,
  ) {
    AppLogger.info('Setting up Realtime subscription for produce: $farmerId');
    final channel = _client.channel('public:produce:farmer_id=$farmerId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'produce',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'farmer_id',
        value: farmerId,
      ),
      callback: (payload) {
        AppLogger.info('Realtime produce change payload received');
        onChange();
      },
    ).subscribe();

    return channel;
  }

  @override
  RealtimeChannel subscribeToMarketPrices(
    void Function() onChange,
  ) {
    AppLogger.info('Setting up Realtime subscription for market prices');
    final channel = _client.channel('public:market_prices');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'market_prices',
      callback: (payload) {
        AppLogger.info('Realtime market price change payload received');
        onChange();
      },
    ).subscribe();

    return channel;
  }
}
