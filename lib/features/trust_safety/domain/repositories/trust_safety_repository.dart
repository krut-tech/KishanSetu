import 'dart:io';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/trust_safety/domain/models/dispute_model.dart';
import 'package:farmer_market_app/features/trust_safety/domain/models/kyc_document_model.dart';

/// Contract for Trust & Safety: KYC verification, disputes/reports, and admin moderation.
abstract class TrustSafetyRepository {
  // ---- KYC (own) ----
  Future<AppResult<KycDocumentModel?>> getMyLatestKycDocument(String userId);
  Future<AppResult<String>> uploadKycFile({required String userId, required File file});
  Future<AppResult<KycDocumentModel>> submitKycDocument(KycDocumentModel document);

  // ---- Disputes (own) ----
  Future<AppResult<List<DisputeModel>>> getMyDisputes(String userId);
  Future<AppResult<DisputeModel>> fileDispute(DisputeModel dispute);

  // ---- Admin: users ----
  Future<AppResult<List<UserProfile>>> adminGetUsers({String? role, String? search});
  Future<AppResult<void>> adminSetAccountStatus(String userId, String status, {String? reason});

  // ---- Admin: KYC queue ----
  Future<AppResult<List<KycDocumentModel>>> adminGetKycQueue({String status = 'pending'});
  Future<AppResult<void>> adminReviewKyc(String documentId, String status, {String? rejectionReason});

  // ---- Admin: listing moderation ----
  Future<AppResult<List<ProduceModel>>> adminGetProduceForModeration({String? moderationStatus});
  Future<AppResult<void>> adminModerateProduce(String produceId, String status, {String? note});

  // ---- Admin: disputes ----
  Future<AppResult<List<DisputeModel>>> adminGetDisputes({String? status});
  Future<AppResult<void>> adminResolveDispute(String disputeId, String status, {String? resolutionNote});
}
