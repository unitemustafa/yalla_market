import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/theme/app_theme.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('slides and returns correctly in $direction', (tester) async {
      await tester.pumpWidget(_app(direction: direction));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final left = tester.getTopLeft(find.byKey(const ValueKey('detail'))).dx;
      expect(direction == TextDirection.ltr ? left : -left, greaterThan(0));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const ValueKey('detail'))).dx, 0);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(find.byKey(const ValueKey('detail')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reduced motion keeps the new page stationary', (tester) async {
    await tester.pumpWidget(_app(disableAnimations: true));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(find.byKey(const ValueKey('detail'))).dx, 0);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  TextDirection direction = TextDirection.ltr,
  bool disableAnimations = false,
}) => MaterialApp(
  theme: AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: Directionality(textDirection: direction, child: child!),
  ),
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              key: const ValueKey('detail'),
              body: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ),
          ),
        ),
        child: const Text('Open'),
      ),
    ),
  ),
);
