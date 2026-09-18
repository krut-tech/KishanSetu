import 'package:flutter/material.dart';

/// Centralized animation durations, curves, and accessibility checks.
class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve bounceSubtle = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;

  /// Returns true if animations are enabled according to system accessibility preferences.
  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.of(context).disableAnimations;
  }
}
