import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';

/// Reusable human-readable error state widget with retry action.
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              title ?? context.l10n.errorOccurred,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.paddingLarge),
              AppButton(
                label: context.l10n.retry,
                onPressed: onRetry,
                icon: Icons.refresh,
                width: 180,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
