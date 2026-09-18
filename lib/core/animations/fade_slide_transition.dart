import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/animations/app_animations.dart';

/// Reusable Fade + Slight Slide Entrance Animation widget for screens and card lists.
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;
  final Duration? delay;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.beginOffset = const Offset(0.0, 0.08),
    this.curve = AppAnimations.smoothCurve,
    this.delay,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.delay != null) {
      Future.delayed(widget.delay!, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
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
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
