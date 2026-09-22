import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_state.dart';

/// Central AuthNotifier managing authentication session, profile updates, and GoRouter refresh events.
class AuthNotifier extends ChangeNotifier {
  final AuthRepository _repository;
  final ChangeNotifier _routingNotifier = ChangeNotifier();
  StreamSubscription<dynamic>? _authSubscription;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  UserProfile? get profile => _state.profile;
  User? get user => _state.user;
  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;

  RealtimeChannel? _profileChannel;

  Listenable get authRoutingListenable => _routingNotifier;

  AuthNotifier(this._repository) {
    _init();
  }

  void _updateState(AuthState newState) {
    final bool routingChanged = _state.status != newState.status ||
        _state.user?.id != newState.user?.id ||
        _state.profile?.role != newState.profile?.role ||
        _state.profile?.isProfileComplete != newState.profile?.isProfileComplete;

    _state = newState;
    notifyListeners();
    if (routingChanged) {
      _routingNotifier.notifyListeners();
    }
  }

  void initSession() {
    _init();
  }

  void _setupProfileRealtime(String userId) {
    if (_profileChannel != null) return;
    try {
      _profileChannel = _repository.subscribeToProfile(userId, (updatedProfile) {
        AppLogger.info('AuthNotifier received realtime profile update for ${updatedProfile.fullName}');
        _updateState(_state.copyWith(profile: updatedProfile));
      });
    } catch (e) {
      AppLogger.warning('Failed to subscribe to profile realtime updates: $e');
    }
  }

  void _cleanupProfileRealtime() {
    _profileChannel?.unsubscribe();
    _profileChannel = null;
  }

  void _init() {
    try {
      _authSubscription?.cancel();
      _authSubscription = _repository.onAuthStateChanges.listen((sbAuthState) async {
        final user = sbAuthState.session?.user;
        if (user != null) {
          if (_state.user?.id != user.id || _state.status != AuthStatus.authenticated) {
            await _fetchProfileForUser(user);
          }
        } else {
          _cleanupProfileRealtime();
          _updateState(_state.copyWith(
            status: AuthStatus.unauthenticated,
            user: null,
            profile: null,
            isLoading: false,
          ));
        }
      }, onError: (e) {
        AppLogger.error('Auth state listener error: $e');
      });

      final currentUser = _repository.currentUser;
      if (currentUser != null) {
        _fetchProfileForUser(currentUser);
      } else {
        _cleanupProfileRealtime();
        _updateState(_state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        ));
      }
    } catch (e) {
      AppLogger.warning('AuthNotifier _init deferred or uninitialized: $e');
      _cleanupProfileRealtime();
      _updateState(_state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      ));
    }
  }

  Future<bool> _fetchProfileForUser(User user) async {
    _updateState(_state.copyWith(isLoading: true, user: user));
    final result = await _repository.getUserProfile(user.id);
    return result.fold(
      (failure) {
        AppLogger.error('Failed to fetch profile: ${failure.message}');
        // Preserve authenticated user session on network/server error instead of signing out
        final fallbackProfile = _state.profile ??
            UserProfile(
              id: user.id,
              fullName: user.userMetadata?['full_name'] as String? ??
                  user.userMetadata?['name'] as String? ??
                  'User',
            );

        _updateState(_state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          profile: fallbackProfile,
          isLoading: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (profile) {
        _updateState(_state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          profile: profile,
          isLoading: false,
          clearError: true,
        ));
        _setupProfileRealtime(user.id);
        return true;
      },
    );
  }

  Future<bool> signIn(String email, String password) async {
    _updateState(_state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.signIn(email: email, password: password);
    return result.fold(
      (failure) {
        _updateState(_state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (authResponse) async {
        if (authResponse.user != null) {
          final profileSuccess = await _fetchProfileForUser(authResponse.user!);
          if (!profileSuccess) {
            return false;
          }
        } else {
          _updateState(_state.copyWith(
            isLoading: false,
            errorMessage: 'Login failed: Invalid user session received.',
          ));
          return false;
        }
        return true;
      },
    );
  }

  Future<bool> signInWithGoogle() async {
    _updateState(_state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.signInWithGoogle();
    return result.fold(
      (failure) {
        _updateState(_state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (success) async {
        final currentUser = _repository.currentUser;
        if (currentUser != null) {
          final profileSuccess = await _fetchProfileForUser(currentUser);
          if (!profileSuccess) return false;
        } else {
          _updateState(_state.copyWith(isLoading: false));
        }
        return success;
      },
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    _updateState(_state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: role,
    );
    return result.fold(
      (failure) {
        _updateState(_state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (authResponse) async {
        if (authResponse.session == null) {
          _updateState(_state.copyWith(
            isLoading: false,
            errorMessage: 'Account created! Please check your email to confirm your account before logging in.',
          ));
          return false;
        }
        if (authResponse.user != null) {
          final profile = UserProfile(
            id: authResponse.user!.id,
            fullName: fullName,
            phone: phone,
            role: role,
          );
          final updateResult = await _repository.updateUserProfile(profile);
          return updateResult.fold(
            (failure) {
              _updateState(_state.copyWith(isLoading: false, errorMessage: failure.message));
              return false;
            },
            (savedProfile) {
              _updateState(_state.copyWith(
                status: AuthStatus.authenticated,
                user: authResponse.user,
                profile: savedProfile,
                isLoading: false,
                clearError: true,
              ));
              return true;
            },
          );
        }
        return true;
      },
    );
  }

  Future<bool> selectRole(UserRole role) async {
    if (_state.profile == null) return false;
    _updateState(_state.copyWith(isLoading: true, clearError: true));

    final updatedProfile = _state.profile!.copyWith(role: role);
    final result = await _repository.updateUserProfile(updatedProfile);

    return result.fold(
      (failure) {
        _updateState(_state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (savedProfile) {
        _updateState(_state.copyWith(isLoading: false, profile: savedProfile));
        return true;
      },
    );
  }

  Future<bool> updateProfile(UserProfile updatedProfile) async {
    _updateState(_state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.updateUserProfile(updatedProfile);

    return result.fold(
      (failure) {
        _updateState(_state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (savedProfile) {
        _updateState(_state.copyWith(isLoading: false, profile: savedProfile));
        return true;
      },
    );
  }

  Future<bool> sendPasswordReset(String email) async {
    _updateState(_state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.sendPasswordResetEmail(email);
    return result.fold(
      (failure) {
        _updateState(_state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (_) {
        _updateState(_state.copyWith(isLoading: false));
        return true;
      },
    );
  }

  Future<bool> resetPassword(String newPassword) async {
    _updateState(_state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.resetPassword(newPassword);
    return result.fold(
      (failure) {
        _updateState(_state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (_) {
        _updateState(_state.copyWith(isLoading: false));
        return true;
      },
    );
  }

  Future<void> signOut() async {
    _updateState(_state.copyWith(isLoading: true));
    _cleanupProfileRealtime();
    await _repository.signOut();
    _updateState(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  void dispose() {
    _cleanupProfileRealtime();
    _authSubscription?.cancel();
    _routingNotifier.dispose();
    super.dispose();
  }
}
