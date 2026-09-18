import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';

/// Abstract contract for authentication operations and profile management.
abstract class AuthRepository {
  Stream<AuthState> get onAuthStateChanges;
  User? get currentUser;

  Future<AppResult<AuthResponse>> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  });

  Future<AppResult<AuthResponse>> signIn({
    required String email,
    required String password,
  });

  Future<AppResult<bool>> signInWithGoogle();

  Future<AppResult<void>> sendPasswordResetEmail(String email);

  Future<AppResult<void>> resetPassword(String newPassword);

  Future<AppResult<void>> signOut();

  Future<AppResult<UserProfile>> getUserProfile(String userId);

  Future<AppResult<UserProfile>> updateUserProfile(UserProfile profile);
}
