import 'package:equatable/equatable.dart';

/// Result row of the find_nearby_mandis RPC.
class NearbyMandiModel extends Equatable {
  final String id;
  final String name;
  final String? state;
  final String? district;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const NearbyMandiModel({
    required this.id,
    required this.name,
    this.state,
    this.district,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  factory NearbyMandiModel.fromMap(Map<String, dynamic> map) {
    return NearbyMandiModel(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      state: map['state'] as String?,
      district: map['district'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, name, state, district, latitude, longitude, distanceKm];
}
