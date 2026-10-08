import 'package:equatable/equatable.dart';

/// A report/dispute filed by one user, optionally against another, an order, or an offer.
class DisputeModel extends Equatable {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? relatedOrderId;
  final String? relatedOfferId;
  final String type; // quality_issue, payment_issue, no_show, fraud, harassment, other
  final String description;
  final String status; // open, investigating, resolved, dismissed
  final String? resolutionNote;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String? reporterName;
  final String? reportedUserName;

  const DisputeModel({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    this.relatedOrderId,
    this.relatedOfferId,
    required this.type,
    required this.description,
    this.status = 'open',
    this.resolutionNote,
    this.createdAt,
    this.resolvedAt,
    this.reporterName,
    this.reportedUserName,
  });

  factory DisputeModel.fromMap(Map<String, dynamic> map) {
    String? reporterName;
    if (map['reporter_profile'] is Map) {
      reporterName = (map['reporter_profile'] as Map<String, dynamic>)['full_name'] as String?;
    }
    String? reportedUserName;
    if (map['reported_profile'] is Map) {
      reportedUserName = (map['reported_profile'] as Map<String, dynamic>)['full_name'] as String?;
    }

    return DisputeModel(
      id: map['id'] as String,
      reporterId: map['reporter_id'] as String,
      reportedUserId: map['reported_user_id'] as String?,
      relatedOrderId: map['related_order_id'] as String?,
      relatedOfferId: map['related_offer_id'] as String?,
      type: (map['type'] as String?) ?? 'other',
      description: (map['description'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'open',
      resolutionNote: map['resolution_note'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      resolvedAt: map['resolved_at'] != null ? DateTime.tryParse(map['resolved_at'] as String) : null,
      reporterName: reporterName,
      reportedUserName: reportedUserName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporter_id': reporterId,
      if (reportedUserId != null) 'reported_user_id': reportedUserId,
      if (relatedOrderId != null) 'related_order_id': relatedOrderId,
      if (relatedOfferId != null) 'related_offer_id': relatedOfferId,
      'type': type,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [
        id,
        reporterId,
        reportedUserId,
        relatedOrderId,
        relatedOfferId,
        type,
        description,
        status,
        resolutionNote,
        createdAt,
        resolvedAt,
        reporterName,
        reportedUserName,
      ];
}
