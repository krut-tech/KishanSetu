import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

/// Immutable state object for authentication status, user session, and profile data.
class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;

  /// True when the user has a valid session but their profile could not be
  /// loaded (offline / backend error) and no cached copy exists.
  ///
  /// This must never be confused with an *incomplete* profile: the router keeps
  /// the user on a recoverable "retry" screen instead of sending a fully
  /// registered user back to "Complete Your Profile".
  final bool profileLoadFailed;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.profileLoadFailed = false,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get hasRole => profile?.role != null;
  bool get isProfileComplete => profile?.isProfileComplete ?? false;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
    UserProfile? profile,
    bool clearProfile = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? profileLoadFailed,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      profile: clearProfile ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      profileLoadFailed: profileLoadFailed ?? this.profileLoadFailed,
    );
  }

  @override
  List<Object?> get props =>
      [status, user, profile, isLoading, errorMessage, profileLoadFailed];
}
