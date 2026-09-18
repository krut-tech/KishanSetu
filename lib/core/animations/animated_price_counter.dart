import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/animations/app_animations.dart';

/// Animated numeric counter for prices and net realization updates.
class AnimatedPriceCounter extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  const AnimatedPriceCounter({
    super.key,
    required this.value,
    this.prefix = '₹',
    this.suffix = '',
    this.style,
    this.duration = AppAnimations.normal,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppAnimations.shouldAnimate(context)) {
      return Text('$prefix${value.toStringAsFixed(0)}$suffix', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: AppAnimations.smoothCurve,
      builder: (context, currentValue, child) {
        return Text(
          '$prefix${currentValue.toStringAsFixed(0)}$suffix',
          style: style,
        );
      },
    );
  }
}
