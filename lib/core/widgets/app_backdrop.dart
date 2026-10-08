import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';

/// Slowly drifting "aurora" background (leaf green + wheat gold orbs) shown
/// behind every screen. Wrapped once in MaterialApp.builder.
class AppBackdrop extends StatefulWidget {
  final Widget child;

  const AppBackdrop({super.key, required this.child});

  @override
  State<AppBackdrop> createState() => _AppBackdropState();
}

class _AppBackdropState extends State<AppBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return ColoredBox(
      color: base,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _AuroraPainter(
                  t: Curves.easeInOut.transform(_controller.value),
                  isDark: isDark,
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final bool isDark;

  _AuroraPainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    void orb(Offset c, double r, Color color) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    final w = size.width;
    final h = size.height;

    orb(
      Offset(w * (1.0 - 0.15 * t), h * (0.08 + 0.05 * t)),
      w * 0.85,
      AppColors.leaf.withValues(alpha: isDark ? 0.26 : 0.16),
    );
    orb(
      Offset(w * (-0.1 + 0.12 * t), h * (0.92 - 0.06 * t)),
      w * 0.75,
      AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.20),
    );
    orb(
      Offset(w * 0.5, h * (0.5 + 0.04 * t)),
      w * 0.9,
      AppColors.primary.withValues(alpha: isDark ? 0.10 : 0.05),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t || old.isDark != isDark;
}
