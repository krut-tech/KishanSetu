import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';

/// Centralized text styles and visual decorations.
class AppStyles {
  AppStyles._();

  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get priceStyle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.priceHighlight,
      );

  static BoxDecoration cardDecoration(BuildContext context, {Color? backgroundColor, Color? borderColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: backgroundColor ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      border: Border.all(
        color: borderColor ?? colorScheme.outline,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
