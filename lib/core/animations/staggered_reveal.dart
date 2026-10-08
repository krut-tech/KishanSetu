import 'package:flutter/material.dart';

/// Fades + lifts its child in, offset by [index] so lists cascade in.
///
/// ```dart
/// StaggeredReveal(index: i, child: ProduceCard(...))
/// ```
class StaggeredReveal extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration step;

  const StaggeredReveal({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 60),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;

    const base = 450;
    final delay = step.inMilliseconds * (index > 8 ? 8 : index);
    final total = base + delay;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
