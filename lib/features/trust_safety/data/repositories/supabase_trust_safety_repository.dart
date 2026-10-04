import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/trust_safety/domain/models/dispute_model.dart';
import 'package:farmer_market_app/features/trust_safety/domain/models/kyc_document_model.dart';
import 'package:farmer_market_app/features/trust_safety/domain/repositories/trust_safety_repository.dart';

class SupabaseTrustSafetyRepository implements TrustSafetyRepository {
  final SupabaseClient _client;

  SupabaseTrustSafetyRepository(this._client);

  @override
  Future<AppResult<KycDocumentModel?>> getMyLatestKycDocument(String userId) async {
    try {
      AppLogger.info('Fetching latest KYC document for user: $userId');
      final response = await _client
          .from('kyc_documents')
          .select()
          .eq('user_id', userId)
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return right(null);
      return right(KycDocumentModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching KYC document', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching KYC document: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching KYC document', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<String>> uploadKycFile({required String userId, required File file}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.id != userId) {
        return left(const AuthFailure('You are not authorized to upload this document.'));
      }
      final ext = file.path.contains('.') ? file.path.split('.').last.toLowerCase() : 'jpg';
      final storagePath = '$userId/${DateTime.now().microsecondsSinceEpoch}.$ext';
      AppLogger.info('Uploading KYC file to $storagePath');
      await _client.storage.from('kyc-documents').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      // kyc-documents is a PRIVATE bucket; store the storage path, not a public URL.
      // Readers (owner / admin) resolve it to a signed URL on demand via createSignedUrl.
      return right(storagePath);
    } on SocketException catch (e) {
      AppLogger.error('Network error uploading KYC file', e);
      return left(const NetworkFailure());
    } on StorageException catch (e) {
      AppLogger.error('Storage failure uploading KYC file: ${e.message}', e);
      return left(DatabaseFailure(e.message));
    } catch (e, stack) {
      AppLogger.error('Unknown failure uploading KYC file', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<KycDocumentModel>> submitKycDocument(KycDocumentModel document) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.id != document.userId) {
        return left(const AuthFailure('You are not authorized to submit this document.'));
      }
      AppLogger.info('Submitting KYC document for user: ${document.userId}');
      final response = await _client.from('kyc_documents').insert(document.toMap()).select().single();
      return right(KycDocumentModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error submitting KYC document', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure submitting KYC document: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure submitting KYC document', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<List<DisputeModel>>> getMyDisputes(String userId) async {
    try {
      AppLogger.info('Fetching disputes for user: $userId');
      final response = await _client
          .from('disputes')
          .select('*, reporter_profile:reporter_id(full_name), reported_profile:reported_user_id(full_name)')
          .or('reporter_id.eq.$userId,reported_user_id.eq.$userId')
          .order('created_at', ascending: false);
      final list = (response as List).map((r) => DisputeModel.fromMap(r as Map<String, dynamic>)).toList();
      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching disputes', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching disputes: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching disputes', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<DisputeModel>> fileDispute(DisputeModel dispute) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null || currentUser.id != dispute.reporterId) {
        return left(const AuthFailure('You are not authorized to file this report.'));
      }
      AppLogger.info('Filing dispute of type: ${dispute.type}');
      final response = await _client.from('disputes').insert(dispute.toMap()).select().single();
      return right(DisputeModel.fromMap(response));
    } on SocketException catch (e) {
      AppLogger.error('Network error filing dispute', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure filing dispute: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure filing dispute', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<List<UserProfile>>> adminGetUsers({String? role, String? search}) async {
    try {
      AppLogger.info('Admin fetching users: role=$role, search=$search');
      var query = _client.from('profiles').select();
      if (role != null && role.isNotEmpty && role != 'all') {
        query = query.eq('role', role);
      }
      if (search != null && search.trim().isNotEmpty) {
        final term = '%${search.trim()}%';
        query = query.or('full_name.ilike.$term,phone.ilike.$term,company_name.ilike.$term');
      }
      final response = await query.order('created_at', ascending: false).limit(100);
      final list = (response as List).map((r) => UserProfile.fromMap(r as Map<String, dynamic>)).toList();
      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching users', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching users: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching users', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> adminSetAccountStatus(String userId, String status, {String? reason}) async {
    try {
      AppLogger.info('Admin setting account status for $userId to $status');
      await _client.rpc('admin_set_account_status', params: {
        'p_user_id': userId,
        'p_status': status,
        'p_reason': reason,
      });
      return right(null);
    } on SocketException catch (e) {
      AppLogger.error('Network error setting account status', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure setting account status: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure setting account status', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<List<KycDocumentModel>>> adminGetKycQueue({String status = 'pending'}) async {
    try {
      AppLogger.info('Admin fetching KYC queue: status=$status');
      var query = _client.from('kyc_documents').select('*, profile:user_id(full_name, role)');
      if (status != 'all') {
        query = query.eq('status', status);
      }
      final response = await query.order('submitted_at', ascending: true);
      final list = (response as List).map((r) => KycDocumentModel.fromMap(r as Map<String, dynamic>)).toList();
      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching KYC queue', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching KYC queue: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching KYC queue', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> adminReviewKyc(String documentId, String status, {String? rejectionReason}) async {
    try {
      AppLogger.info('Admin reviewing KYC document $documentId: $status');
      await _client.rpc('admin_review_kyc', params: {
        'p_document_id': documentId,
        'p_status': status,
        'p_rejection_reason': rejectionReason,
      });
      return right(null);
    } on SocketException catch (e) {
      AppLogger.error('Network error reviewing KYC document', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure reviewing KYC document: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure reviewing KYC document', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<List<ProduceModel>>> adminGetProduceForModeration({String? moderationStatus}) async {
    try {
      AppLogger.info('Admin fetching produce for moderation: $moderationStatus');
      var query = _client.from('produce').select('*, farmer_profile:farmer_id(full_name, district)');
      if (moderationStatus != null && moderationStatus != 'all') {
        query = query.eq('moderation_status', moderationStatus);
      }
      final response = await query.order('created_at', ascending: false).limit(100);
      final list = (response as List).map((r) => ProduceModel.fromMap(r as Map<String, dynamic>)).toList();
      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching produce for moderation', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching produce for moderation: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching produce for moderation', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> adminModerateProduce(String produceId, String status, {String? note}) async {
    try {
      AppLogger.info('Admin moderating produce $produceId: $status');
      await _client.rpc('admin_moderate_produce', params: {
        'p_produce_id': produceId,
        'p_status': status,
        'p_note': note,
      });
      return right(null);
    } on SocketException catch (e) {
      AppLogger.error('Network error moderating produce', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure moderating produce: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure moderating produce', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<List<DisputeModel>>> adminGetDisputes({String? status}) async {
    try {
      AppLogger.info('Admin fetching disputes: status=$status');
      var query = _client
          .from('disputes')
          .select('*, reporter_profile:reporter_id(full_name), reported_profile:reported_user_id(full_name)');
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      final response = await query.order('created_at', ascending: false);
      final list = (response as List).map((r) => DisputeModel.fromMap(r as Map<String, dynamic>)).toList();
      return right(list);
    } on SocketException catch (e) {
      AppLogger.error('Network error fetching admin disputes', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure fetching admin disputes: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure fetching admin disputes', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppResult<void>> adminResolveDispute(String disputeId, String status, {String? resolutionNote}) async {
    try {
      AppLogger.info('Admin resolving dispute $disputeId: $status');
      await _client.rpc('admin_resolve_dispute', params: {
        'p_dispute_id': disputeId,
        'p_status': status,
        'p_resolution_note': resolutionNote,
      });
      return right(null);
    } on SocketException catch (e) {
      AppLogger.error('Network error resolving dispute', e);
      return left(const NetworkFailure());
    } on PostgrestException catch (e) {
      AppLogger.error('Database failure resolving dispute: ${e.message}', e);
      return left(DatabaseFailure(e.message, code: e.code));
    } catch (e, stack) {
      AppLogger.error('Unknown failure resolving dispute', e, stack);
      return left(UnknownFailure(e.toString()));
    }
  }
}
