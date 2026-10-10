import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/core/routing/app_router.dart';
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
            // This widget sits in MaterialApp.builder, ABOVE the Navigator, so
            // its own context cannot show dialogs. Use the router's navigator,
            // retrying briefly in case it is not mounted yet (e.g. on splash).
            BuildContext? navContext;
            for (var i = 0; i < 10; i++) {
              navContext = ref
                  .read(appRouterProvider)
                  .routerDelegate
                  .navigatorKey
                  .currentContext;
              if (navContext != null) break;
              await Future<void>.delayed(const Duration(milliseconds: 500));
              if (!mounted) return;
            }
            if (navContext == null) {
              AppLogger.warning('Update dialog skipped: navigator not ready.');
              return;
            }
            await UpdateDialog.show(navContext);
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
