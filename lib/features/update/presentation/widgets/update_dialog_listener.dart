import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/update/presentation/controllers/update_controller.dart';
import 'package:farmer_market_app/features/update/presentation/widgets/update_dialog.dart';

/// Top-level listener widget that monitors [updateNotifierProvider] and displays
/// the localized [UpdateDialog] when an update is available.
class UpdateDialogListener extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateDialogListener({super.key, required this.child});

  @override
  ConsumerState<UpdateDialogListener> createState() =>
      _UpdateDialogListenerState();
}

class _UpdateDialogListenerState extends ConsumerState<UpdateDialogListener> {
  bool _isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateState>(updateNotifierProvider, (previous, next) {
      if (next.status == UpdateStatus.available &&
          !next.hasShownPopup &&
          !_isDialogShowing) {
        _isDialogShowing = true;
        ref.read(updateNotifierProvider.notifier).markPopupShown();

        AppLogger.info('Update available! Presenting update popup dialog.');

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          try {
            await UpdateDialog.show(context);
          } catch (e) {
            AppLogger.error('Error displaying update dialog: $e');
          } finally {
            _isDialogShowing = false;
          }
        });
      }
    });

    return widget.child;
  }
}
