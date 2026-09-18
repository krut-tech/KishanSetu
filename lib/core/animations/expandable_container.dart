import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/animations/app_animations.dart';

/// Smooth expandable container for accordions, details, and negotiation histories.
class ExpandableContainer extends StatelessWidget {
  final bool isExpanded;
  final Widget child;
  final Duration duration;

  const ExpandableContainer({
    super.key,
    required this.isExpanded,
    required this.child,
    this.duration = AppAnimations.normal,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity, height: 0),
      secondChild: child,
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: duration,
      sizeCurve: AppAnimations.smoothCurve,
    );
  }
}
