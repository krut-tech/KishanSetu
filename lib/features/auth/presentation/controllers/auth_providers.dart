import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:farmer_market_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_notifier.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  return SupabaseAuthRepository(supabaseClient);
});

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return AuthNotifier(repository);
});
