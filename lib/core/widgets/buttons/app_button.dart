import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';

enum AppButtonStyle { primary, secondary, outlined }

/// Reusable button widget with touch-friendly sizes and loading states.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonStyle style;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget childContent = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                style == AppButtonStyle.outlined ? colorScheme.primary : colorScheme.onPrimary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppConstants.paddingSmall),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    Widget button;
    switch (style) {
      case AppButtonStyle.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: Size(width ?? double.infinity, AppConstants.minTouchTargetSize),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
          ),
          child: childContent,
        );
        break;
      case AppButtonStyle.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            minimumSize: Size(width ?? double.infinity, AppConstants.minTouchTargetSize),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
          ),
          child: childContent,
        );
        break;
      case AppButtonStyle.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            minimumSize: Size(width ?? double.infinity, AppConstants.minTouchTargetSize),
            side: BorderSide(color: colorScheme.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
          ),
          child: childContent,
        );
        break;
    }

    return SizedBox(
      width: width,
      child: button,
    );
  }
}
