import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/bootstrap/app_bootstrap_provider.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';

/// Initial splash and bootstrap screen for application initialization and error recovery.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    AppLogger.info('SplashScreen build called');
    final bootstrapState = ref.watch(appBootstrapProvider);

    String appName;
    String tagline;
    try {
      appName = context.l10n.appName;
      tagline = context.l10n.tagline;
    } catch (_) {
      appName = AppConstants.appName;
      tagline = 'Direct Farm-to-Buyer Marketplace & Real-time Prices';
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingXLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    bootstrapState.hasError ? Icons.cloud_off : Icons.agriculture,
                    size: 64,
                    color: bootstrapState.hasError ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),

                // App Title & Tagline
                Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXLarge * 1.5),

                // State Content: Loading vs Error
                if (bootstrapState.hasError) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Connection Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          bootstrapState.errorMessage ?? 'Service initialization failed.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        if (bootstrapState.technicalError != null) ...[
                          const SizedBox(height: AppConstants.paddingSmall),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showDetails = !_showDetails;
                              });
                            },
                            icon: Icon(
                              _showDetails ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              _showDetails ? 'Hide Details' : 'Show Details',
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                          if (_showDetails) ...[
                            Container(
                              padding: const EdgeInsets.all(AppConstants.paddingSmall),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: AppRadius.borderSm,
                              ),
                              child: Text(
                                bootstrapState.technicalError!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: AppConstants.paddingMedium),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppConstants.paddingMedium,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderSm,
                              ),
                            ),
                            onPressed: () {
                              ref.read(appBootstrapProvider.notifier).initialize();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry Connection'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
