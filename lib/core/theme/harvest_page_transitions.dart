import 'package:flutter/material.dart';

/// Fade + gentle rise page transition. The outgoing page cross-fades out so it
/// works with the transparent scaffolds shown over [AppBackdrop].
class HarvestPageTransitionsBuilder extends PageTransitionsBuilder {
  const HarvestPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(exit),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(enter),
          child: child,
        ),
      ),
    );
  }
}

class HarvestPageTransitions {
  HarvestPageTransitions._();

  static const PageTransitionsTheme theme = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: HarvestPageTransitionsBuilder(),
      TargetPlatform.iOS: HarvestPageTransitionsBuilder(),
      TargetPlatform.windows: HarvestPageTransitionsBuilder(),
      TargetPlatform.macOS: HarvestPageTransitionsBuilder(),
      TargetPlatform.linux: HarvestPageTransitionsBuilder(),
      TargetPlatform.fuchsia: HarvestPageTransitionsBuilder(),
    },
  );
}
