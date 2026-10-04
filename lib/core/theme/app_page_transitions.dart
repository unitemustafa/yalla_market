import 'package:flutter/material.dart';

/// Horizontal navigation without the zoom transition's dimmed backdrop.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final direction = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    final curve = CurveTween(curve: Curves.easeInOutCubic);
    return SlideTransition(
      position: secondaryAnimation
          .drive(curve)
          .drive(
            Tween<Offset>(
              begin: Offset.zero,
              end: Offset(-direction * 0.25, 0),
            ),
          ),
      child: SlideTransition(
        position: animation
            .drive(curve)
            .drive(
              Tween<Offset>(begin: Offset(direction, 0), end: Offset.zero),
            ),
        child: child,
      ),
    );
  }
}
