/// Global constants for the Farmer Market Linkage app.
class AppConstants {
  AppConstants._();

  static const String appName = 'Farmer Market Linkage';
  static const String appVersion = '1.0.0';

  // Supported Locales
  static const String localeEnglish = 'en';
  static const String localeHindi = 'hi';
  static const String localeGujarati = 'gu';

  // Layout Padding & Margins
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Touch Target Accessibility
  static const double minTouchTargetSize = 48.0;

  // Rupee Currency Symbol
  static const String currencySymbol = '₹';

  // Shimmer Duration
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
}
