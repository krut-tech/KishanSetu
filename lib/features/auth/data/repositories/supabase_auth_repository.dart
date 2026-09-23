import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/domain/repositories/auth_repository.dart';

/// Supabase implementation of AuthRepository.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient? _client;

  SupabaseAuthRepository(this._client);

  SupabaseClient get _effectiveClient {
    final client = _client ?? SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not initialized yet.');
    }
    return client;
  }

  @override
  Stream<AuthState> get onAuthStateChanges {
    final client = _client ?? SupabaseService.client;
    if (client == null) return const Stream.empty();
    return client.auth.onAuthStateChange;
  }

  @override
  User? get currentUser {
    final client = _client ?? SupabaseService.client;
    if (client == null) return null;
    return client.auth.currentUser;
  }

  String _sanitizeAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    if (lower.contains('user already registered') || lower.contains('already exists')) {
      return 'An account with this email address already exists. Please log in.';
    }
    if (lower.contains('password should be at least')) {
      return 'Password must be at least 6 characters long.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Your email address is not confirmed yet. Please check your inbox and confirm your account.';
    }
    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }
    if (lower.contains('user not found')) {
      return 'No account found with this email address. Please register first.';
    }
    return message;
  }

  @override
  Future<AppResult<AuthResponse>> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final client = _effectiveClient;
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.value,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      return right(response);
    } on AuthException catch (e) {
      AppLogger.error('SignUp AuthException: ${e.message}');
      return left(AuthFailure(_sanitizeAuthError(e.message)));
    } catch (e, st) {
      AppLogger.error('SignUp Unexpected Error: $e', e, st);
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('timeout') ||
          errorStr.contains('network')) {
        return left(const NetworkFailure('Network error. Please check your internet connection and try again.'));
      }
      return left(const ServerFailure('Failed to complete sign up. Please try again.'));
    }
  }

  @override
  Future<AppResult<AuthResponse>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final client = _effectiveClient;
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return right(response);
    } on AuthException catch (e) {
      AppLogger.error('SignIn AuthException (statusCode: ${e.statusCode}): ${e.message}');
      return left(AuthFailure(_sanitizeAuthError(e.message)));
    } catch (e, st) {
      AppLogger.error('SignIn Unexpected Error: $e', e, st);
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('timeout') ||
          errorStr.contains('network')) {
        return left(const NetworkFailure('Network error. Please check your internet connection and try again.'));
      }
      return left(const ServerFailure('Authentication failed. Please try again.'));
    }
  }

  @override
  Future<AppResult<bool>> signInWithGoogle() async {
    try {
      final client = _effectiveClient;
      final response = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback',
      );
      return right(response);
    } on AuthException catch (e) {
      AppLogger.error('Google SignIn AuthException: ${e.message}');
      return left(AuthFailure(_sanitizeAuthError(e.message)));
    } catch (e, st) {
      AppLogger.error('Google SignIn Unexpected Error: $e', e, st);
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('timeout') ||
          errorStr.contains('network')) {
        return left(const NetworkFailure('Network error. Please check your internet connection and try again.'));
      }
      return left(const ServerFailure('Google Sign-In failed. Please try again.'));
    }
  }

  @override
  Future<AppResult<void>> sendPasswordResetEmail(String email) async {
    try {
      final client = _effectiveClient;
      await client.auth.resetPasswordForEmail(email);
      return right(null);
    } on AuthException catch (e) {
      return left(AuthFailure(_sanitizeAuthError(e.message)));
    } catch (e) {
      return left(const ServerFailure('Failed to send reset email. Please try again.'));
    }
  }

  @override
  Future<AppResult<void>> resetPassword(String newPassword) async {
    try {
      final client = _effectiveClient;
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return right(null);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(const ServerFailure('Failed to update password.'));
    }
  }

  @override
  Future<AppResult<void>> signOut() async {
    try {
      final client = _effectiveClient;
      await client.auth.signOut();
      return right(null);
    } catch (e) {
      return left(const ServerFailure('Failed to sign out.'));
    }
  }

  @override
  Future<AppResult<UserProfile>> getUserProfile(String userId) async {
    try {
      final client = _effectiveClient;
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      final user = currentUser;
      final userMeta = user?.userMetadata;
      final googleName = userMeta?['full_name'] as String? ??
          userMeta?['name'] as String?;
      final googleAvatar = userMeta?['avatar_url'] as String? ??
          userMeta?['picture'] as String?;
      final roleStr = userMeta?['role'] as String?;
      final phoneStr = userMeta?['phone'] as String?;

      if (data == null) {
        final newProfile = UserProfile(
          id: userId,
          fullName: googleName ?? 'User',
          avatarUrl: googleAvatar,
          phone: phoneStr,
          role: roleStr != null ? UserRole.fromString(roleStr) : null,
        );
        return right(newProfile);
      }

      var profile = UserProfile.fromMap(data);
      if ((profile.fullName.isEmpty || profile.fullName == 'User') &&
          googleName != null &&
          googleName.isNotEmpty) {
        profile = profile.copyWith(fullName: googleName);
      }
      if ((profile.avatarUrl == null || profile.avatarUrl!.isEmpty) &&
          googleAvatar != null &&
          googleAvatar.isNotEmpty) {
        profile = profile.copyWith(avatarUrl: googleAvatar);
      }

      return right(profile);
    } on PostgrestException catch (e) {
      AppLogger.error('Fetch profile database error: ${e.message}');
      return left(DatabaseFailure('Database error loading profile: ${e.message}'));
    } catch (e, st) {
      AppLogger.error('Fetch profile unexpected error: $e', e, st);
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('timeout') ||
          errorStr.contains('network')) {
        return left(const NetworkFailure('Network error loading profile. Please check your connection.'));
      }
      return left(const ServerFailure('Failed to fetch user profile. Please try again.'));
    }
  }

  @override
  Future<AppResult<UserProfile>> updateUserProfile(UserProfile profile) async {
    try {
      final client = _effectiveClient;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthFailure('Your session has expired. Please sign in again.'));
      }

      // Never trust a caller-supplied profile id. The authenticated Supabase
      // session is the source of truth for which profile may be written.
      final safeProfile = profile.id == currentUser.id
          ? profile
          : profile.copyWith(id: currentUser.id);

      final updatedData = await client
          .from('profiles')
          .upsert(safeProfile.toMap())
          .select()
          .single();

      return right(UserProfile.fromMap(updatedData));
    } on PostgrestException catch (e) {
      AppLogger.error('Update profile database error: ${e.message}');
      return left(DatabaseFailure(e.message));
    } catch (e, st) {
      AppLogger.error('Update profile unexpected error: $e', e, st);
      return left(const ServerFailure('Failed to update profile.'));
    }
  }

  @override
  RealtimeChannel subscribeToProfile(
    String userId,
    void Function(UserProfile? profile) onProfileChange,
  ) {
    AppLogger.info('Setting up Realtime subscription for profile: $userId');
    final client = _effectiveClient;
    final uniqueId = DateTime.now().microsecondsSinceEpoch;
    final channel = client.channel('public:profiles:id=${userId}_$uniqueId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: userId,
      ),
      callback: (payload) {
        AppLogger.info('Realtime profile change payload received for $userId');
        if (payload.eventType == PostgresChangeEvent.delete || payload.newRecord.isEmpty) {
          AppLogger.warning('Realtime profile DELETE event received for $userId');
          onProfileChange(null);
        } else if (payload.newRecord.isNotEmpty) {
          onProfileChange(UserProfile.fromMap(payload.newRecord));
        }
      },
    ).subscribe();

    return channel;
  }
}
