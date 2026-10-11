import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';

/// `destructive` is a red button for irreversible actions (delete, cancel offer).
enum AppButtonStyle { primary, secondary, outlined, destructive }

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
    final minSize =
        Size(width ?? double.infinity, AppConstants.minTouchTargetSize);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
    );

    Widget childContent = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                style == AppButtonStyle.outlined
                    ? colorScheme.primary
                    : (style == AppButtonStyle.destructive
                        ? colorScheme.onError
                        : colorScheme.onPrimary),
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
              // Flexible + ellipsis: long Hindi/Gujarati labels no longer overflow
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );

    Widget filled(Color bg, Color fg) => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            elevation: 0,
            minimumSize: minSize,
            shape: shape,
          ),
          child: childContent,
        );

    Widget button;
    switch (style) {
      case AppButtonStyle.primary:
        button = filled(colorScheme.primary, colorScheme.onPrimary);
        break;
      case AppButtonStyle.secondary:
        button = filled(colorScheme.secondary, colorScheme.onSecondary);
        break;
      case AppButtonStyle.destructive:
        button = filled(colorScheme.error, colorScheme.onError);
        break;
      case AppButtonStyle.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            minimumSize: minSize,
            side: BorderSide(color: colorScheme.primary, width: 1.5),
            shape: shape,
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
