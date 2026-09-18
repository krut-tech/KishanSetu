import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/animations/app_animations.dart';

/// Animated transition widget when status badges update state.
class AnimatedStatusSwitcher extends StatelessWidget {
  final Widget child;

  const AnimatedStatusSwitcher({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppAnimations.shouldAnimate(context)) {
      return child;
    }

    return AnimatedSwitcher(
      duration: AppAnimations.fast,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
