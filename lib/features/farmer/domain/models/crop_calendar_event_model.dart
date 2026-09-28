import 'package:equatable/equatable.dart';

/// Crop calendar reminder mapping Supabase crop_calendar_events table.
class CropCalendarEventModel extends Equatable {
  final String id;
  final String farmerId;
  final String cropName;
  final String eventType; // sowing, irrigation, fertilizer, pest_control, harvest, other
  final DateTime eventDate;
  final int notifyBeforeDays;
  final String? note;
  final bool isCompleted;
  final DateTime? createdAt;

  const CropCalendarEventModel({
    required this.id,
    required this.farmerId,
    required this.cropName,
    required this.eventType,
    required this.eventDate,
    this.notifyBeforeDays = 1,
    this.note,
    this.isCompleted = false,
    this.createdAt,
  });

  factory CropCalendarEventModel.fromMap(Map<String, dynamic> map) {
    return CropCalendarEventModel(
      id: map['id'] as String,
      farmerId: map['farmer_id'] as String,
      cropName: (map['crop_name'] as String?) ?? '',
      eventType: (map['event_type'] as String?) ?? 'other',
      eventDate: DateTime.parse(map['event_date'] as String),
      notifyBeforeDays: (map['notify_before_days'] as num?)?.toInt() ?? 1,
      note: map['note'] as String?,
      isCompleted: (map['is_completed'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final d = eventDate;
    final dateStr =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {
      if (id.isNotEmpty) 'id': id,
      'farmer_id': farmerId,
      'crop_name': cropName,
      'event_type': eventType,
      'event_date': dateStr,
      'notify_before_days': notifyBeforeDays,
      if (note != null) 'note': note,
      'is_completed': isCompleted,
    };
  }

  CropCalendarEventModel copyWith({
    String? id,
    String? farmerId,
    String? cropName,
    String? eventType,
    DateTime? eventDate,
    int? notifyBeforeDays,
    String? note,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return CropCalendarEventModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      cropName: cropName ?? this.cropName,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      notifyBeforeDays: notifyBeforeDays ?? this.notifyBeforeDays,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        farmerId,
        cropName,
        eventType,
        eventDate,
        notifyBeforeDays,
        note,
        isCompleted,
        createdAt,
      ];
}
