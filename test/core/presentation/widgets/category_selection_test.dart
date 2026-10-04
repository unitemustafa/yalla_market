import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/selection/category_selection.dart';

void main() {
  testWidgets('pressing a category does not paint a grey halo', (tester) async {
    var taps = 0;
    const paintKey = ValueKey('selector_paint');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: paintKey,
            child: Material(
              color: Colors.white,
              child: CategorySelectionTap(
                onTap: () => taps++,
                child: const SizedBox(width: 100, height: 64),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = await _pixels(tester, paintKey);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CategorySelectionTap)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(await _pixels(tester, paintKey), orderedEquals(before));
    expect(taps, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('results fade smoothly and outgoing results cannot be tapped', (
    tester,
  ) async {
    final selection = ValueNotifier('first');
    addTearDown(selection.dispose);
    var oldTaps = 0;
    var newTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<String>(
            valueListenable: selection,
            builder: (context, value, _) => CategoryContentTransition(
              selectionKey: value,
              child: SizedBox(
                width: 200,
                height: value == 'first' ? 160 : 80,
                child: Align(
                  alignment: value == 'first'
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
                  child: TextButton(
                    onPressed: value == 'first'
                        ? () => oldTaps++
                        : () => newTaps++,
                    child: Text(value),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final oldPosition = tester.getCenter(find.text('first'));
    selection.value = 'second';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('second'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    expect(tester.getSize(find.byType(CategoryContentTransition)).height, 80);
    await tester.tapAt(oldPosition);
    expect(oldTaps, 0);
    await tester.pumpAndSettle();
    expect(find.text('first'), findsNothing);
    await tester.tap(find.text('second'));
    expect(newTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion switches categories immediately', (tester) async {
    final selection = ValueNotifier('first');
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ValueListenableBuilder<String>(
            valueListenable: selection,
            builder: (_, value, _) => CategoryContentTransition(
              selectionKey: value,
              child: Text(value),
            ),
          ),
        ),
      ),
    );
    selection.value = 'second';
    await tester.pump();
    expect(find.text('second'), findsOneWidget);
    expect(find.text('first'), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}

Future<Uint8List> _pixels(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
}
