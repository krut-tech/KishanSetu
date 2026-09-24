import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/bootstrap/app_bootstrap_provider.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/core/notifications/push_notification_service.dart';
import 'package:farmer_market_app/core/routing/route_names.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:farmer_market_app/features/auth/presentation/screens/buyer_profile_screen.dart';
import 'package:farmer_market_app/features/auth/presentation/screens/complete_profile_screen.dart';
import 'package:farmer_market_app/features/auth/presentation/screens/farmer_profile_screen.dart';
import 'package:farmer_market_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:farmer_market_app/features/auth/presentation/screens/login_screen.dart';
import 'package:farmer_market_app/features/auth/presentation/screens/register_screen.dart';
import 'package:farmer_market_app/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:farmer_market_app/features/design_system/presentation/design_system_gallery_screen.dart';
import 'package:farmer_market_app/features/farmer/presentation/screens/add_produce_screen.dart';
import 'package:farmer_market_app/features/home/presentation/buyer_home_screen.dart';
import 'package:farmer_market_app/features/home/presentation/farmer_home_screen.dart';
import 'package:farmer_market_app/features/notifications/presentation/screens/notification_screen.dart';
import 'package:farmer_market_app/features/splash/presentation/splash_screen.dart';

int _goRouterConstructionCount = 0;

/// Centralized GoRouter navigation configuration with auth protection guards and bootstrap check.
final appRouterProvider = Provider<GoRouter>((ref) {
  _goRouterConstructionCount++;
  AppLogger.info('GO_ROUTER_CONSTRUCTED count: $_goRouterConstructionCount');
  AppLogger.info('appRouterProvider building GoRouter');
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final authNotifier = ref.read(authNotifierProvider);
  final bootstrapNotifier = ref.read(appBootstrapProvider.notifier);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: Listenable.merge([
      authNotifier.authRoutingListenable,
      bootstrapNotifier.bootstrapListenable,
    ]),
    redirect: (context, state) {
      final bootstrapState = ref.read(appBootstrapProvider);
      final authNotifier = ref.read(authNotifierProvider);
      final authState = authNotifier.state;
      final location = state.matchedLocation;

      AppLogger.info('GoRouter redirect check: location=$location, isInitialized=${bootstrapState.isInitialized}, isAuthenticated=${authState.isAuthenticated}');

      if (location == RouteNames.designSystem) return null;

      // Ensure app bootstrap initialization is complete and auth session status is resolved
      if (!bootstrapState.isInitialized ||
          authState.status == AuthStatus.initial ||
          (location == RouteNames.splash && authState.isLoading)) {
        return location == RouteNames.splash ? null : RouteNames.splash;
      }

      // Unauthenticated User Guard
      if (!authState.isAuthenticated) {
        final isAuthRoute = location == RouteNames.login ||
            location == RouteNames.register ||
            location == RouteNames.forgotPassword;
        if (location == RouteNames.splash) return RouteNames.login;
        return isAuthRoute ? null : RouteNames.login;
      }

      // Authenticated User Guards
      final profile = authState.profile;
      final isProfileComplete = authState.isProfileComplete;

      // 1. Missing role or incomplete profile -> Complete Profile Setup
      if (profile?.role == null || !isProfileComplete) {
        if (profile?.role == UserRole.farmer) {
          final isFarmerSetupRoute = location == RouteNames.farmerProfile ||
              location == RouteNames.completeProfile ||
              location == RouteNames.roleSelection;
          if (isFarmerSetupRoute) return null;
          return RouteNames.farmerProfile;
        } else if (profile?.role == UserRole.buyer) {
          final isBuyerSetupRoute = location == RouteNames.buyerProfile ||
              location == RouteNames.completeProfile ||
              location == RouteNames.roleSelection;
          if (isBuyerSetupRoute) return null;
          return RouteNames.buyerProfile;
        } else {
          final isRoleSetupRoute = location == RouteNames.completeProfile ||
              location == RouteNames.roleSelection;
          if (isRoleSetupRoute) return null;
          return RouteNames.completeProfile;
        }
      }

      // Role-based cross-route separation guard. Farmer-only routes must not be
      // reachable by a completed buyer through a direct URL/deep link.
      if (location == RouteNames.addProduce && profile?.role != UserRole.farmer) {
        return RouteNames.buyerHome;
      }

      if (profile?.role == UserRole.farmer) {
        if (location == RouteNames.buyerHome || location == RouteNames.buyerProfile) {
          return RouteNames.farmerHome;
        }
      } else if (profile?.role == UserRole.buyer) {
        if (location == RouteNames.farmerHome ||
            location == RouteNames.farmerProfile ||
            location == RouteNames.addProduce) {
          return RouteNames.buyerHome;
        }
      }

      // 3. Authenticated & Profile Complete -> Check pending push notification route first
      if (PushNotificationService.pendingInitialRoute != null &&
          authState.isAuthenticated &&
          authState.isProfileComplete) {
        final pendingRoute = PushNotificationService.pendingInitialRoute!;
        PushNotificationService.pendingInitialRoute = null;
        AppLogger.info('Consuming pending push notification initial route: $pendingRoute');
        return pendingRoute;
      }

      final isAuthFlowScreen = location == RouteNames.login ||
          location == RouteNames.register ||
          location == RouteNames.splash ||
          location == RouteNames.roleSelection ||
          location == RouteNames.completeProfile ||
          location == RouteNames.farmerProfile ||
          location == RouteNames.buyerProfile;

      if (isAuthFlowScreen) {
        return profile?.role == UserRole.buyer
            ? RouteNames.buyerHome
            : RouteNames.farmerHome;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.roleSelection,
        name: 'roleSelection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerProfile,
        name: 'farmerProfile',
        builder: (context, state) => const FarmerProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.buyerProfile,
        name: 'buyerProfile',
        builder: (context, state) => const BuyerProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.completeProfile,
        name: 'completeProfile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerHome,
        name: 'farmerHome',
        builder: (context, state) => const FarmerHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.addProduce,
        name: 'addProduce',
        builder: (context, state) => const AddProduceScreen(),
      ),
      GoRoute(
        path: RouteNames.buyerHome,
        name: 'buyerHome',
        builder: (context, state) => const BuyerHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/offers',
        name: 'offers',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/buyer-offers',
        name: 'buyerOffers',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/my-produce',
        name: 'myProduce',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/market-prices',
        name: 'marketPrices',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: RouteNames.designSystem,
        name: 'designSystem',
        builder: (context, state) => const DesignSystemGalleryScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Navigation Route Error: ${state.error}'),
      ),
    ),
  );

  PushNotificationService.onNavigate = (targetRoute) {
    AppLogger.info('PushNotificationService onNavigate -> $targetRoute');
    try {
      router.go(targetRoute);
    } catch (e) {
      AppLogger.warning('GoRouter error navigating to $targetRoute, falling back to /notifications: $e');
      router.go(RouteNames.notifications);
    }
  };

  return router;
});
