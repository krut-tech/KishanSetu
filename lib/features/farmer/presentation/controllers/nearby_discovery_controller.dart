import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/farmer/domain/models/nearby_mandi_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/nearby_produce_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';

class NearbyDiscoveryState extends Equatable {
  final List<NearbyProduceModel> nearbyProduce;
  final List<NearbyMandiModel> nearbyMandis;
  final double? currentLat;
  final double? currentLng;
  final double radiusKm;
  final bool isLoading;
  final String? errorMessage;

  const NearbyDiscoveryState({
    this.nearbyProduce = const [],
    this.nearbyMandis = const [],
    this.currentLat,
    this.currentLng,
    this.radiusKm = 50,
    this.isLoading = false,
    this.errorMessage,
  });

  NearbyDiscoveryState copyWith({
    List<NearbyProduceModel>? nearbyProduce,
    List<NearbyMandiModel>? nearbyMandis,
    double? currentLat,
    double? currentLng,
    double? radiusKm,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NearbyDiscoveryState(
      nearbyProduce: nearbyProduce ?? this.nearbyProduce,
      nearbyMandis: nearbyMandis ?? this.nearbyMandis,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      radiusKm: radiusKm ?? this.radiusKm,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        nearbyProduce,
        nearbyMandis,
        currentLat,
        currentLng,
        radiusKm,
        isLoading,
        errorMessage,
      ];
}

class NearbyDiscoveryController extends StateNotifier<NearbyDiscoveryState> {
  final FarmerRepository _repository;

  NearbyDiscoveryController(this._repository) : super(const NearbyDiscoveryState());

  /// Requests location permission, reads the device position, then searches.
  Future<void> detectLocationAndSearch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location services are disabled. Please turn on GPS.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        state = state.copyWith(isLoading: false, errorMessage: 'Location permission denied.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location permission is permanently denied. Enable it from app settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      await search(lat: position.latitude, lng: position.longitude);
    } catch (e, stack) {
      AppLogger.error('Failed to detect location for nearby discovery', e, stack);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not fetch your current location.',
      );
    }
  }

  Future<void> search({
    required double lat,
    required double lng,
    double? radiusKm,
  }) async {
    final radius = radiusKm ?? state.radiusKm;
    state = state.copyWith(
      isLoading: true,
      currentLat: lat,
      currentLng: lng,
      radiusKm: radius,
      clearError: true,
    );

    final produceResult = await _repository.findNearbyProduce(lat: lat, lng: lng, radiusKm: radius);
    final mandiResult = await _repository.findNearbyMandis(lat: lat, lng: lng, radiusKm: radius);
    if (!mounted) return;

    String? error;
    var produceList = state.nearbyProduce;
    var mandiList = state.nearbyMandis;
    produceResult.fold((f) => error = f.message, (list) => produceList = list);
    mandiResult.fold((f) => error ??= f.message, (list) => mandiList = list);

    state = state.copyWith(
      isLoading: false,
      nearbyProduce: produceList,
      nearbyMandis: mandiList,
      errorMessage: error,
    );
  }

  /// Re-runs the search with a new radius once the slider is released.
  Future<void> updateRadius(double radiusKm) async {
    final lat = state.currentLat;
    final lng = state.currentLng;
    if (lat == null || lng == null) {
      state = state.copyWith(radiusKm: radiusKm);
      return;
    }
    await search(lat: lat, lng: lng, radiusKm: radiusKm);
  }
}
