import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/layouts/centered_card_carousel.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final count in [2, 3]) {
      testWidgets('wraps in both directions with $count items in $direction', (
        tester,
      ) async {
        await tester.pumpWidget(_carousel(count, direction: direction));
        await tester.pumpAndSettle();
        _expectCentered(tester, 0);

        final forward = direction == TextDirection.ltr ? -240.0 : 240.0;
        // Move backwards from the first item, then forwards across the seam.
        await tester.drag(find.byType(PageView), Offset(-forward, 0));
        await tester.pumpAndSettle();
        _expectCentered(tester, count - 1);

        await tester.drag(find.byType(PageView), Offset(forward, 0));
        await tester.pumpAndSettle();
        _expectCentered(tester, 0);

        await tester.drag(find.byType(PageView), Offset(forward, 0));
        await tester.pumpAndSettle();
        _expectCentered(tester, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('indicators select a card and follow the current page', (
    tester,
  ) async {
    await tester.pumpWidget(_carousel(5));
    await tester.pumpAndSettle();
    _expectCentered(tester, 0);

    await tester.tap(find.bySemanticsLabel('4 / 5'));
    await tester.pumpAndSettle();
    _expectCentered(tester, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resets safely as a refreshed collection changes size', (
    tester,
  ) async {
    await tester.pumpWidget(_carousel(5));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('5 / 5'));
    await tester.pumpAndSettle();
    _expectCentered(tester, 4);

    for (final count in [2, 1, 0, 3]) {
      await tester.pumpWidget(_carousel(count));
      await tester.pumpAndSettle();
      if (count == 0) {
        expect(find.byType(PageView), findsNothing);
      } else {
        _expectCentered(tester, 0);
        if (count == 1) {
          expect(find.byType(InkResponse), findsNothing);
          await tester.drag(find.byType(PageView), const Offset(-240, 0));
          await tester.pumpAndSettle();
          _expectCentered(tester, 0);
        }
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('indicator navigation respects reduced motion in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(_carousel(3, reducedMotion: true));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('3 / 3'));
    await tester.pump();
    _expectCentered(tester, 2);
    expect(tester.takeException(), isNull);
  });
}

Widget _carousel(
  int count, {
  TextDirection direction = TextDirection.ltr,
  bool reducedMotion = false,
}) {
  return MaterialApp(
    theme: reducedMotion ? ThemeData.dark() : ThemeData.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: CenteredCardCarousel(
                itemCount: count,
                itemHeight: 100,
                itemBuilder: (context, index) => ColoredBox(
                  color: Colors.blue,
                  child: Center(child: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _expectCentered(WidgetTester tester, int index) {
  final center = tester.getCenter(find.byType(PageView)).dx;
  final labels = find.text('Item $index').evaluate();
  expect(
    labels.any((element) {
      final rect = tester.getRect(find.byWidget(element.widget));
      return (rect.center.dx - center).abs() < 0.1;
    }),
    isTrue,
    reason: 'Item $index should be centered in the viewport',
  );
  final selected = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.label?.startsWith('${index + 1} / ') == true &&
        widget.properties.selected == true,
  );
  final carousel = tester.widget<CenteredCardCarousel>(
    find.byType(CenteredCardCarousel),
  );
  expect(selected, carousel.itemCount > 1 ? findsOneWidget : findsNothing);
}
