import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/animations/app_animations.dart';

/// Reusable Scale + Fade Transition for dialogs, popups, and badges.
class ScaleFadeTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double beginScale;

  const ScaleFadeTransition({
    super.key,
    required this.child,
    this.duration = AppAnimations.fast,
    this.beginScale = 0.9,
  });

  @override
  State<ScaleFadeTransition> createState() => _ScaleFadeTransitionState();
}

class _ScaleFadeTransitionState extends State<ScaleFadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.smoothCurve,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.smoothCurve,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppAnimations.shouldAnimate(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
