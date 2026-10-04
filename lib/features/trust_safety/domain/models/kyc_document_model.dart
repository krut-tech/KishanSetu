import 'package:equatable/equatable.dart';

/// A KYC identity document submitted by a user for verification.
class KycDocumentModel extends Equatable {
  final String id;
  final String userId;
  final String documentType; // aadhaar, pan, voter_id, driving_license, other
  final String documentNumber;
  final String documentUrl;
  final String status; // pending, verified, rejected
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? userName;
  final String? userRole;

  const KycDocumentModel({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.documentNumber,
    required this.documentUrl,
    this.status = 'pending',
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.userName,
    this.userRole,
  });

  factory KycDocumentModel.fromMap(Map<String, dynamic> map) {
    String? userName;
    String? userRole;
    if (map['profile'] is Map) {
      final p = map['profile'] as Map<String, dynamic>;
      userName = p['full_name'] as String?;
      userRole = p['role'] as String?;
    }
    return KycDocumentModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      documentType: (map['document_type'] as String?) ?? 'other',
      documentNumber: (map['document_number'] as String?) ?? '',
      documentUrl: (map['document_url'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'pending',
      rejectionReason: map['rejection_reason'] as String?,
      submittedAt: map['submitted_at'] != null ? DateTime.tryParse(map['submitted_at'] as String) : null,
      reviewedAt: map['reviewed_at'] != null ? DateTime.tryParse(map['reviewed_at'] as String) : null,
      userName: userName,
      userRole: userRole,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'document_type': documentType,
      'document_number': documentNumber,
      'document_url': documentUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        documentType,
        documentNumber,
        documentUrl,
        status,
        rejectionReason,
        submittedAt,
        reviewedAt,
        userName,
        userRole,
      ];
}
