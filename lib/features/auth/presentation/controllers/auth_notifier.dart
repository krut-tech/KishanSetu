import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/core/notifications/push_notification_service.dart';
import 'package:farmer_market_app/features/auth/data/profile_cache.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_state.dart';

/// Central AuthNotifier managing authentication session, profile updates, and GoRouter refresh events.
///
/// Startup strategy (fast + offline safe):
///  1. A cached copy of the user's profile (if any) is applied immediately so
///     the router can send a returning user straight to their home screen.
///  2. The fresh profile is then fetched in the background and replaces the
///     cached copy.
///  3. If the fetch fails and nothing is cached, [AuthState.profileLoadFailed]
///     is raised. The router shows a retry screen instead of wrongly sending a
///     registered user to "Complete Your Profile".
class AuthNotifier extends ChangeNotifier {
  final AuthRepository _repository;
  final VoidCallback? onSignOutCallback;
  final ChangeNotifier _routingNotifier = ChangeNotifier();
  StreamSubscription<dynamic>? _authSubscription;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  @visibleForTesting
  void setTestState(AuthState testState) {
    _state = testState;
    notifyListeners();
  }

  UserProfile? get profile => _state.profile;
  User? get user => _state.user;
  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;

  RealtimeChannel? _profileChannel;
  String? _subscribedUserId;

  bool _isSignUpInProgress = false;

  // Outer de-duplication: one "load profile" sequence per user at a time.
  String? _inFlightFetchUserId;
  Future<bool>? _inFlightFetchFuture;

  // Inner de-duplication: one network request per user at a time (also covers
  // the background refresh that continues after a cached profile was applied).
  String? _networkFetchUserId;
  Future<bool>? _networkFetchFuture;

  Listenable get authRoutingListenable => _routingNotifier;

  final SupabaseClient? _supabaseClient;

  AuthNotifier(this._repository,
      {SupabaseClient? supabaseClient, this.onSignOutCallback})
      : _supabaseClient = supabaseClient {
    _init();
  }

  Future<void> _syncPushToken(String userId) async {
    final client = _supabaseClient ?? SupabaseService.client;
    if (client != null) {
      try {
        await PushNotificationService().syncDeviceToken(userId, client);
      } catch (e, stack) {
        AppLogger.error('Push token sync error: $e', e, stack);
      }
    }
  }

  Future<void> _deactivatePushToken(String userId) async {
    final client = _supabaseClient ?? SupabaseService.client;
    if (client != null) {
      try {
        await PushNotificationService().deactivateDeviceToken(userId, client);
      } catch (e, stack) {
        AppLogger.error('Push token deactivation error: $e', e, stack);
      }
    }
  }

  void _updateState(AuthState newState) {
    final bool routingChanged = _state.status != newState.status ||
        _state.user?.id != newState.user?.id ||
        _state.profile?.role != newState.profile?.role ||
        _state.profile?.isProfileComplete !=
            newState.profile?.isProfileComplete ||
        _state.profileLoadFailed != newState.profileLoadFailed;

    _state = newState;
    notifyListeners();
    if (routingChanged) {
      _routingNotifier.notifyListeners();
    }
  }

  Future<void> initSession() async {
    await _init();
  }

  /// Re-attempts loading the profile for the current session. Used by the
  /// "Retry" button on the splash/recovery screen.
  Future<void> retryProfileLoad() async {
    final currentUser = _state.user ?? _repository.currentUser;
    if (currentUser == null) {
      await _init();
      return;
    }
    _updateState(_state.copyWith(isLoading: true, user: currentUser));
    await _fetchProfileForUser(currentUser);
  }

  void _setupProfileRealtime(String userId) {
    if (_subscribedUserId == userId && _profileChannel != null) {
      return;
    }
    _cleanupProfileRealtime();
    try {
      _subscribedUserId = userId;
      _profileChannel =
          _repository.subscribeToProfile(userId, (updatedProfile) {
        AppLogger.info(
            'AuthNotifier received realtime profile update for $userId');
        if (_state.user?.id == userId) {
          if (updatedProfile == null) {
            AppLogger.warning('Profile deleted for active user $userId');
            unawaited(ProfileCache.clear(userId));
            _updateState(_state.copyWith(
              clearProfile: true,
              errorMessage: 'Your profile has been deleted.',
            ));
          } else {
            unawaited(ProfileCache.write(updatedProfile));
            _updateState(_state.copyWith(
              profile: updatedProfile,
              profileLoadFailed: false,
            ));
          }
        }
      });
    } catch (e) {
      AppLogger.warning('Failed to subscribe to profile realtime updates: $e');
    }
  }

  void _cleanupProfileRealtime() {
    if (_profileChannel != null) {
      try {
        _profileChannel?.unsubscribe();
      } catch (e) {
        AppLogger.warning('Error unsubscribing profile channel: $e');
      }
      _profileChannel = null;
    }
    _subscribedUserId = null;
  }

  Future<void> _init() async {
    try {
      _authSubscription?.cancel();
      _authSubscription =
          _repository.onAuthStateChanges.listen((sbAuthState) async {
        final user = sbAuthState.session?.user;
        if (user != null) {
          if (_isSignUpInProgress) return;

          final isSameUser = _state.user?.id == user.id;
          final isAlreadyAuthenticated =
              _state.status == AuthStatus.authenticated &&
                  _state.profile != null;
          if (!isSameUser || !isAlreadyAuthenticated) {
            await _fetchProfileForUser(user, useCache: true);
          }
        } else {
          _cleanupProfileRealtime();
          _updateState(_state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
            clearProfile: true,
            isLoading: false,
            profileLoadFailed: false,
          ));
          onSignOutCallback?.call();
        }
      }, onError: (e) {
        AppLogger.error('Auth state listener error: $e');
      });

      final currentUser = _repository.currentUser;
      if (currentUser != null) {
        if (!_isSignUpInProgress) {
          final isSameUser = _state.user?.id == currentUser.id;
          final isAlreadyAuthenticated =
              _state.status == AuthStatus.authenticated &&
                  _state.profile != null;
          if (!isSameUser || !isAlreadyAuthenticated) {
            await _fetchProfileForUser(currentUser, useCache: true);
          }
        }
      } else if (_state.user == null) {
        _cleanupProfileRealtime();
        _updateState(_state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        ));
        onSignOutCallback?.call();
      }
    } catch (e) {
      AppLogger.warning('AuthNotifier _init deferred or uninitialized: $e');
      _cleanupProfileRealtime();
      _updateState(_state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      ));
      onSignOutCallback?.call();
    }
  }

  Future<bool> _fetchProfileForUser(User user, {bool useCache = false}) {
    if (_inFlightFetchUserId == user.id && _inFlightFetchFuture != null) {
      return _inFlightFetchFuture!;
    }
    _inFlightFetchUserId = user.id;
    final future = _doFetchProfileForUser(user, useCache: useCache);
    _inFlightFetchFuture = future;
    future.whenComplete(() {
      if (_inFlightFetchUserId == user.id) {
        _inFlightFetchUserId = null;
        _inFlightFetchFuture = null;
      }
    });
    return future;
  }

  Future<bool> _doFetchProfileForUser(User user,
      {bool useCache = false}) async {
    final hasLiveProfile = _state.user?.id == user.id && _state.profile != null;

    // Fast path: show the cached profile immediately and refresh in background.
    if (useCache && !hasLiveProfile) {
      final cached = await ProfileCache.read(user.id);
      final activeUserId = _state.user?.id;
      final switchedUser = activeUserId != null && activeUserId != user.id;
      if (cached != null && !switchedUser) {
        _updateState(_state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          profile: cached,
          isLoading: false,
          clearError: true,
          profileLoadFailed: false,
        ));
        _setupProfileRealtime(user.id);
        unawaited(_loadProfileFromNetwork(user));
        return true;
      }
    }

    _updateState(_state.copyWith(isLoading: true, user: user));
    return _loadProfileFromNetwork(user);
  }

  Future<bool> _loadProfileFromNetwork(User user) {
    if (_networkFetchUserId == user.id && _networkFetchFuture != null) {
      return _networkFetchFuture!;
    }
    _networkFetchUserId = user.id;
    final future = _doNetworkFetch(user);
    _networkFetchFuture = future;
    future.whenComplete(() {
      if (_networkFetchUserId == user.id) {
        _networkFetchUserId = null;
        _networkFetchFuture = null;
      }
    });
    return future;
  }

  Future<bool> _doNetworkFetch(User user) async {
    final result = await _repository.getUserProfile(user.id);

    // The session changed (sign-out / account switch) while we were waiting.
    if (_state.user?.id != user.id) {
      AppLogger.info(
          'Discarding profile response for ${user.id}: session changed.');
      return false;
    }

    return result.fold(
      (failure) {
        AppLogger.error('Failed to fetch profile: ${failure.message}');
        final existing = _state.profile;

        if (existing != null) {
          // Keep the cached / last-known profile. A temporary backend or
          // network failure must never bounce a registered user around.
          _updateState(_state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            isLoading: false,
            clearError: true,
            profileLoadFailed: false,
          ));
          _setupProfileRealtime(user.id);
          return true;
        }

        // Nothing to show: surface a recoverable error state (not an
        // "incomplete profile").
        _updateState(_state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearProfile: true,
          isLoading: false,
          errorMessage: failure.message,
          profileLoadFailed: true,
        ));
        return false;
      },
      (profile) {
        unawaited(ProfileCache.write(profile));
        _updateState(_state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          profile: profile,
          isLoading: false,
          clearError: true,
          profileLoadFailed: false,
        ));
        _setupProfileRealtime(user.id);
        _syncPushToken(profile.id);
        return true;
      },
    );
  }

  Future<bool> signIn(String email, String password) async {
    _updateState(_state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.signIn(email: email, password: password);
    return result.fold(
      (failure) {
        _updateState(
            _state.copyWith(isLoading: false, errorMessage: failure.message));
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
        _updateState(
            _state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (success) async {
        final currentUser = _repository.currentUser;
        if (currentUser != null && currentUser.id != _state.user?.id) {
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
    _isSignUpInProgress = true;
    _updateState(_state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      return await result.fold(
        (failure) async {
          _updateState(
              _state.copyWith(isLoading: false, errorMessage: failure.message));
          return false;
        },
        (authResponse) async {
          if (authResponse.session == null) {
            _updateState(_state.copyWith(
              isLoading: false,
              errorMessage:
                  'Account created! Please check your email to confirm your account before logging in.',
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
                _updateState(_state.copyWith(
                    isLoading: false, errorMessage: failure.message));
                return false;
              },
              (savedProfile) {
                unawaited(ProfileCache.write(savedProfile));
                _updateState(_state.copyWith(
                  status: AuthStatus.authenticated,
                  user: authResponse.user,
                  profile: savedProfile,
                  isLoading: false,
                  clearError: true,
                  profileLoadFailed: false,
                ));
                _setupProfileRealtime(authResponse.user!.id);
                _syncPushToken(savedProfile.id);
                return true;
              },
            );
          }
          return true;
        },
      );
    } finally {
      _isSignUpInProgress = false;
    }
  }

  Future<bool> selectRole(UserRole role) async {
    if (_state.profile == null) return false;
    _updateState(_state.copyWith(isLoading: true, clearError: true));

    final updatedProfile = _state.profile!.copyWith(role: role);
    final result = await _repository.updateUserProfile(updatedProfile);

    return result.fold(
      (failure) {
        _updateState(
            _state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (savedProfile) {
        unawaited(ProfileCache.write(savedProfile));
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
        _updateState(
            _state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (savedProfile) {
        unawaited(ProfileCache.write(savedProfile));
        _updateState(_state.copyWith(
          isLoading: false,
          profile: savedProfile,
          profileLoadFailed: false,
        ));
        return true;
      },
    );
  }

  Future<bool> sendPasswordReset(String email) async {
    _updateState(_state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.sendPasswordResetEmail(email);
    return result.fold(
      (failure) {
        _updateState(
            _state.copyWith(isLoading: false, errorMessage: failure.message));
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
        _updateState(
            _state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (_) {
        _updateState(_state.copyWith(isLoading: false));
        return true;
      },
    );
  }

  Future<void> signOut() async {
    final userId = _state.user?.id;
    _updateState(_state.copyWith(isLoading: true));
    _cleanupProfileRealtime();
    if (userId != null) {
      await _deactivatePushToken(userId);
      await ProfileCache.clear(userId);
    }
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
