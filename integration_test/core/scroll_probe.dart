import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keep real list motion throughout the window instead of flinging at an edge.
Future<Map<String, num>> scrollProbe(WidgetTester tester) async {
  Finder vertical() => find
      .byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      )
      .first;
  final watch = Stopwatch()..start();
  var forward = true;
  var flings = 0;
  var moving = 0;
  var reversals = 0;
  var distance = 0.0;
  while (watch.elapsed < const Duration(seconds: 30)) {
    final position = tester.state<ScrollableState>(vertical()).position;
    expect(position.maxScrollExtent, greaterThan(position.minScrollExtent));
    if (forward && position.pixels >= position.maxScrollExtent - 1) {
      forward = false;
      reversals++;
    } else if (!forward && position.pixels <= position.minScrollExtent + 1) {
      forward = true;
      reversals++;
    }
    final before = position.pixels;
    await tester.fling(vertical(), Offset(0, forward ? -600 : 600), 1400);
    await tester.pumpAndSettle();
    final delta = (position.pixels - before).abs();
    distance += delta;
    if (delta > 1) moving++;
    flings++;
  }
  expect(moving, greaterThanOrEqualTo(5));
  expect(
    moving / flings,
    greaterThanOrEqualTo(0.8),
    reason: 'Window spent too long stationary at an edge',
  );
  return {
    'elapsed_ms': watch.elapsedMilliseconds,
    'flings': flings,
    'moving_flings': moving,
    'distance_px': distance,
    'edge_reversals': reversals,
  };
}
