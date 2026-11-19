import 'package:flutter/material.dart';

/// Keeps the platform transition and back gesture, with a shorter Android
/// animation so the product and its source catalog overlap for less time.
class ProductDetailPageRoute<T> extends MaterialPageRoute<T> {
  ProductDetailPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => _androidDuration(
    const Duration(milliseconds: 260),
    super.transitionDuration,
  );

  @override
  Duration get reverseTransitionDuration => _androidDuration(
    const Duration(milliseconds: 220),
    super.reverseTransitionDuration,
  );

  Duration _androidDuration(Duration duration, Duration platformDuration) {
    final context = navigator!.context;
    if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
      return Duration.zero;
    }
    return Theme.of(context).platform == TargetPlatform.android
        ? duration
        : platformDuration;
  }
}
