/// Global constants for the KisanSetu app.
class AppConstants {
  AppConstants._();

  static const String appName = 'KisanSetu';
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

  // Border Radius (Harvest Glass: softer, rounder)
  static const double borderRadiusSmall = 10.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 22.0;

  // Touch Target Accessibility
  static const double minTouchTargetSize = 52.0;

  // Rupee Currency Symbol
  static const String currencySymbol = '₹';

  // Shimmer Duration
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
}
