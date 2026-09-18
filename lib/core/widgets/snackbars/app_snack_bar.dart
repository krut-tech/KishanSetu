import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';

enum SnackBarType { success, error, warning, info }

/// Reusable floating snackbar notifications with status feedback styling.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color bg;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        bg = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        bg = AppColors.error;
        icon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        bg = AppColors.warning;
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        bg = AppColors.info;
        icon = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
    );
  }
}
