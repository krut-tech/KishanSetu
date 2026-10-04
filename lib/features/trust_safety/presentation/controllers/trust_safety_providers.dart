import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/features/trust_safety/data/repositories/supabase_trust_safety_repository.dart';
import 'package:farmer_market_app/features/trust_safety/domain/repositories/trust_safety_repository.dart';
import 'package:farmer_market_app/features/trust_safety/presentation/controllers/admin_controller.dart';
import 'package:farmer_market_app/features/trust_safety/presentation/controllers/dispute_controller.dart';
import 'package:farmer_market_app/features/trust_safety/presentation/controllers/kyc_controller.dart';

final trustSafetyRepositoryProvider = Provider<TrustSafetyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider) ?? Supabase.instance.client;
  return SupabaseTrustSafetyRepository(client);
});

final kycControllerProvider = StateNotifierProvider<KycController, KycState>((ref) {
  return KycController(ref.watch(trustSafetyRepositoryProvider));
});

final disputeControllerProvider = StateNotifierProvider<DisputeController, DisputeState>((ref) {
  return DisputeController(ref.watch(trustSafetyRepositoryProvider));
});

final adminControllerProvider = StateNotifierProvider<AdminController, AdminState>((ref) {
  return AdminController(ref.watch(trustSafetyRepositoryProvider));
});
