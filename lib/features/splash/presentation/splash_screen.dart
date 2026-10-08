import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/bootstrap/app_bootstrap_provider.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';

/// Initial splash and bootstrap screen: animated logo, then loader or error recovery.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  bool _showDetails = false;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
  );

  late final Animation<double> _textFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('SplashScreen build called');
    final bootstrapState = ref.watch(appBootstrapProvider);
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String appName;
    String tagline;
    try {
      appName = context.l10n.appName;
      tagline = context.l10n.tagline;
    } catch (_) {
      appName = AppConstants.appName;
      tagline = 'Direct Farm-to-Buyer Marketplace & Real-time Prices';
    }

    final hasError = bootstrapState.hasError;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingXLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final v = _pulse.value;
                          return Opacity(
                            opacity: (1 - v) * 0.45,
                            child: Container(
                              width: 120 + 50 * v,
                              height: 120 + 50 * v,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: hasError ? cs.error : AppColors.accent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: hasError ? null : AppColors.goldGradient,
                            color: hasError ? cs.errorContainer : null,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.35),
                                blurRadius: 40,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            hasError ? Icons.cloud_off : Icons.agriculture,
                            size: 56,
                            color: hasError ? cs.error : AppColors.forest,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(_textFade),
                    child: Column(
                      children: [
                        Text(
                          appName,
                          textAlign: TextAlign.center,
                          style: textTheme.displaySmall?.copyWith(
                            fontSize: 38,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          tagline,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXLarge * 1.5),
                if (hasError)
                  AppCard(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      children: [
                        Text(
                          context.l10n.connectionError,
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          bootstrapState.errorMessage ??
                              context.l10n.serviceInitializationFailed,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
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
                              _showDetails
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                            ),
                            label: Text(
                              _showDetails
                                  ? context.l10n.hideDetails
                                  : context.l10n.showDetails,
                            ),
                          ),
                          if (_showDetails)
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(AppConstants.paddingSmall),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusSmall,
                                ),
                              ),
                              child: Text(
                                bootstrapState.technicalError!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: cs.error,
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: AppConstants.paddingMedium),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(appBootstrapProvider.notifier).initialize();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.retryConnection),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
