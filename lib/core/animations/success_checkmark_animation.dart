import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/animations/app_animations.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';

/// Animated success checkmark for deal closures and order confirmations.
class SuccessCheckmarkAnimation extends StatefulWidget {
  final double size;
  final Color color;

  const SuccessCheckmarkAnimation({
    super.key,
    this.size = 64.0,
    this.color = AppColors.success,
  });

  @override
  State<SuccessCheckmarkAnimation> createState() => _SuccessCheckmarkAnimationState();
}

class _SuccessCheckmarkAnimationState extends State<SuccessCheckmarkAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.bounceSubtle,
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
      return Icon(Icons.check_circle_rounded, size: widget.size, color: widget.color);
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.all(widget.size * 0.15),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle_rounded,
          size: widget.size,
          color: widget.color,
        ),
      ),
    );
  }
}
