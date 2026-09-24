import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:farmer_market_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_notifier.dart';

import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';
import 'package:farmer_market_app/features/notifications/presentation/controllers/notification_notifier.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  return SupabaseAuthRepository(supabaseClient);
});

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  final repository = ref.read(authRepositoryProvider);
  final supabaseClient = ref.read(supabaseClientProvider);
  return AuthNotifier(repository, supabaseClient: supabaseClient, onSignOutCallback: () {
    ref.invalidate(buyerDashboardNotifierProvider);
    ref.invalidate(marketplaceControllerProvider);
    ref.invalidate(buyerOfferControllerProvider);
    ref.invalidate(farmerDashboardNotifierProvider);
    ref.invalidate(produceControllerProvider);
    ref.invalidate(marketPriceControllerProvider);
    ref.invalidate(offerControllerProvider);
    ref.invalidate(notificationNotifierProvider);
  });
});
