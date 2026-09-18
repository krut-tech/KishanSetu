import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/features/buyer/data/repositories/supabase_buyer_repository.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_dashboard_notifier.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_offer_controller.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/marketplace_controller.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';

/// Provider exposing production [BuyerRepository].
final buyerRepositoryProvider = Provider<BuyerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider) ?? Supabase.instance.client;
  return SupabaseBuyerRepository(client);
});

/// Controller managing Buyer Dashboard state and subscriptions.
final buyerDashboardNotifierProvider =
    StateNotifierProvider<BuyerDashboardNotifier, BuyerDashboardState>((ref) {
  final buyerRepo = ref.watch(buyerRepositoryProvider);
  final farmerRepo = ref.watch(farmerRepositoryProvider);
  return BuyerDashboardNotifier(buyerRepo, farmerRepo);
});

/// Controller managing Marketplace browsing, search, filter, and sort.
final marketplaceControllerProvider =
    StateNotifierProvider<MarketplaceController, MarketplaceState>((ref) {
  final repository = ref.watch(buyerRepositoryProvider);
  return MarketplaceController(repository);
});

/// Controller managing Buyer's submitted offers.
final buyerOfferControllerProvider =
    StateNotifierProvider<BuyerOfferController, BuyerOfferState>((ref) {
  final repository = ref.watch(buyerRepositoryProvider);
  return BuyerOfferController(repository);
});
