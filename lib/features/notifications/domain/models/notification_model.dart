import 'package:equatable/equatable.dart';

enum NotificationType {
  newOffer('new_offer'),
  offerAccepted('offer_accepted'),
  offerRejected('offer_rejected'),
  offerCancelled('offer_cancelled'),
  counterOffer('counter_offer'),
  newMessage('new_message'),
  produceInterest('produce_interest'),
  marketPriceUpdate('market_price_update'),
  system('system');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String val) {
    return NotificationType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => NotificationType.system,
    );
  }
}

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? relatedId;
  final String? relatedType;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.relatedType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      relatedId: json['related_id'] as String?,
      relatedType: json['related_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? relatedId,
    String? relatedType,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        message,
        relatedId,
        relatedType,
        isRead,
        createdAt,
      ];
}
