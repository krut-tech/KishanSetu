import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';

/// Reusable confirmation dialogs, alert dialogs, and bottom sheets.
class AppDialogs {
  AppDialogs._();

  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)),
        content: Text(message, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        actionsPadding: const EdgeInsets.all(AppSpacing.lg),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: cancelLabel,
                  style: AppButtonStyle.outlined,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: confirmLabel,
                  style: isDestructive ? AppButtonStyle.secondary : AppButtonStyle.primary,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> showModalBottomSheetWidget({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}
