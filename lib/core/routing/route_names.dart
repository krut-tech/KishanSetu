/// Route path constants for GoRouter.
class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String roleSelection = '/role-selection';
  static const String farmerProfile = '/farmer-profile';
  static const String buyerProfile = '/buyer-profile';
  static const String completeProfile = '/complete-profile';
  static const String farmerHome = '/farmer-home';
  static const String buyerHome = '/buyer-home';
  static const String addProduce = '/add-produce';
  static const String notifications = '/notifications';
  static const String designSystem = '/design-system';

  // Deep-link targets used by push notification navigation (see
  // PushNotificationService.resolveRouteFromData and the push-notification
  // Edge Function's resolveRoute). Previously these were only referenced as
  // raw string literals in app_router.dart and were wired to the wrong
  // screen (NotificationScreen) instead of the real feature screens.
  static const String offers = '/offers';
  static const String buyerOffers = '/buyer-offers';
  static const String myProduce = '/my-produce';
  static const String marketPrices = '/market-prices';
}
