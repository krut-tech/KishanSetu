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

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get hasRole => profile?.role != null;
  bool get isProfileComplete => profile?.isProfileComplete ?? false;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, profile, isLoading, errorMessage];
}
