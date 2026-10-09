import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';

/// Reusable glass-style card: soft border, press-scale feedback and a short
/// fade-up entrance. Used across all features, so it carries the new look.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool animateIn;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.animateIn = true,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppConstants.borderRadiusLarge);

    final padded = Padding(
      padding: widget.padding ?? const EdgeInsets.all(AppConstants.paddingMedium),
      child: widget.child,
    );

    final inner = widget.onTap == null
        ? padded
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) {
                if (_pressed != v) setState(() => _pressed = v);
              },
              borderRadius: radius,
              child: padded,
            ),
          );

    final card = AnimatedScale(
      scale: _pressed ? 0.975 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              (isDark ? cs.surface.withValues(alpha: 0.78) : cs.surface),
          borderRadius: radius,
          border: Border.all(color: widget.borderColor ?? cs.outline),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.30)
                  : const Color(0xFF238B4D).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: inner,
      ),
    );

    if (!widget.animateIn || MediaQuery.of(context).disableAnimations) {
      return card;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - v)),
          child: child,
        ),
      ),
      child: card,
    );
  }
}
