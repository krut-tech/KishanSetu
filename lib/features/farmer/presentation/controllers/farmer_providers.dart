import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/features/farmer/data/repositories/supabase_farmer_repository.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_dashboard_notifier.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/market_price_controller.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/offer_controller.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/produce_controller.dart';

final farmerRepositoryProvider = Provider<FarmerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider) ?? Supabase.instance.client;
  return SupabaseFarmerRepository(client);
});

final farmerDashboardNotifierProvider =
    StateNotifierProvider<FarmerDashboardNotifier, FarmerDashboardState>((ref) {
  final repository = ref.watch(farmerRepositoryProvider);
  return FarmerDashboardNotifier(repository);
});

final produceControllerProvider =
    StateNotifierProvider<ProduceController, ProduceState>((ref) {
  final repository = ref.watch(farmerRepositoryProvider);
  return ProduceController(repository);
});

final marketPriceControllerProvider =
    StateNotifierProvider<MarketPriceController, MarketPriceState>((ref) {
  final repository = ref.watch(farmerRepositoryProvider);
  return MarketPriceController(repository);
});

final offerControllerProvider =
    StateNotifierProvider<OfferController, OfferState>((ref) {
  final repository = ref.watch(farmerRepositoryProvider);
  return OfferController(repository);
});
