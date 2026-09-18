import 'package:flutter/material.dart';

/// System-wide color palette focused on agriculture, accessibility, and trust.
class AppColors {
  AppColors._();

  // Primary - Fresh Agriculture Green
  static const Color primary = Color(0xFF1E6F3D);
  static const Color primaryDark = Color(0xFF144A29);
  static const Color primaryLight = Color(0xFFE2F3E7);

  // Secondary - Earth & Forest Green (Unified Agricultural Accent)
  static const Color secondary = Color(0xFF166534);
  static const Color secondaryDark = Color(0xFF14532D);
  static const Color secondaryLight = Color(0xFFDCFCE7);

  // Status Badges & Transaction State Colors
  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color pendingFg = Color(0xFFB45309);

  static const Color acceptedBg = Color(0xFFDCFCE7);
  static const Color acceptedFg = Color(0xFF15803D);

  static const Color rejectedBg = Color(0xFFFEE2E2);
  static const Color rejectedFg = Color(0xFFB91C1C);

  static const Color expiredBg = Color(0xFFF1F5F9);
  static const Color expiredFg = Color(0xFF64748B);

  static const Color inTransitBg = Color(0xFFE0F2FE);
  static const Color inTransitFg = Color(0xFF0369A1);

  static const Color completedBg = Color(0xFFD1FAE5);
  static const Color completedFg = Color(0xFF047857);

  static const Color activeBg = Color(0xFFECFDF5);
  static const Color activeFg = Color(0xFF065F46);

  static const Color draftBg = Color(0xFFF3F4F6);
  static const Color draftFg = Color(0xFF374151);

  // Standard Alerts & Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  // Neutral Light Theme
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Neutral Dark Theme
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Price & Realization Highlights
  static const Color priceHighlight = Color(0xFF059669);
  static const Color netRealizationBadge = Color(0xFF047857);
  static const Color netRealizationBg = Color(0xFFECFDF5);
}
