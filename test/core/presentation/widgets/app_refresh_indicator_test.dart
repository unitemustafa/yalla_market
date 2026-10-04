import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/app_refresh_indicator.dart';

void main() {
  testWidgets('Given a short pull, when released, then it does not refresh', (
    tester,
  ) async {
    var calls = 0;
    await _pumpRefreshHarness(tester, onRefresh: () async => calls += 1);

    final gesture = await tester.startGesture(const Offset(200, 120));
    await gesture.moveBy(const Offset(0, 70));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets(
    'Given a completed pull, when refresh is pending, then a second pull does not start another refresh',
    (tester) async {
      final refresh = Completer<void>();
      var calls = 0;
      await _pumpRefreshHarness(
        tester,
        onRefresh: () {
          calls += 1;
          return refresh.future;
        },
      );

      await _pullToRefresh(tester);
      expect(calls, 1);

      await _pullToRefresh(tester);
      expect(calls, 1);

      refresh.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Given an anchor below the header, when pulled, then the anchored content moves down while the header stays fixed',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppRefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                physics: AppRefreshIndicator.scrollPhysics,
                children: const [
                  SizedBox(key: ValueKey('fixed-header'), height: 80),
                  AppRefreshAnchor(),
                  SizedBox(key: ValueKey('anchored-content'), height: 900),
                ],
              ),
            ),
          ),
        ),
      );

      final headerBefore = tester.getTopLeft(
        find.byKey(const ValueKey('fixed-header')),
      );
      final contentBefore = tester.getTopLeft(
        find.byKey(const ValueKey('anchored-content')),
      );
      final gesture = await tester.startGesture(const Offset(200, 120));
      await gesture.moveBy(const Offset(0, 110));
      await tester.pump();

      expect(
        tester.getTopLeft(find.byKey(const ValueKey('fixed-header'))),
        headerBefore,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('anchored-content'))).dy,
        greaterThan(contentBefore.dy),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Given a rejected notification predicate, when pulled, then it does not refresh',
    (tester) async {
      var calls = 0;
      await _pumpRefreshHarness(
        tester,
        onRefresh: () async => calls += 1,
        notificationPredicate: (_) => false,
      );

      await _pullToRefresh(tester);

      expect(calls, 0);
    },
  );

  testWidgets(
    'Given the list is scrolled away from its edge, when pulled from the middle, then it does not refresh',
    (tester) async {
      var calls = 0;
      await _pumpRefreshHarness(tester, onRefresh: () async => calls += 1);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await _pullToRefresh(tester);

      expect(calls, 0);
    },
  );

  testWidgets(
    'Given an empty short list, when pulled past the threshold, then it refreshes',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: AppRefreshIndicator(
              onRefresh: () async => calls += 1,
              child: ListView(
                physics: AppRefreshIndicator.scrollPhysics,
                children: const [AppRefreshAnchor()],
              ),
            ),
          ),
        ),
      );

      await _pullToRefresh(tester);

      expect(calls, 1);
    },
  );

  testWidgets(
    'Given an armed pull is partially reversed, then the anchor gap shrinks while content before it stays in place',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: AppRefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                physics: AppRefreshIndicator.scrollPhysics,
                children: const [
                  SizedBox(key: ValueKey('header'), height: 80),
                  AppRefreshAnchor(key: ValueKey('anchor')),
                  SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );
      final headerBefore = tester.getTopLeft(
        find.byKey(const ValueKey('header')),
      );
      final gesture = await tester.startGesture(const Offset(200, 180));
      await gesture.moveBy(const Offset(0, 220));
      await tester.pump();
      final armedGap = tester
          .getSize(find.byKey(const ValueKey('anchor')))
          .height;

      await gesture.moveBy(const Offset(0, -50));
      await tester.pump();

      expect(
        tester.getTopLeft(find.byKey(const ValueKey('header'))).dy,
        closeTo(headerBefore.dy, 3),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('anchor'))).height,
        lessThan(armedGap),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Given an armed pull is canceled, then it does not refresh', (
    tester,
  ) async {
    var calls = 0;
    await _pumpRefreshHarness(tester, onRefresh: () async => calls += 1);

    final gesture = await tester.startGesture(const Offset(200, 120));
    await gesture.moveBy(const Offset(0, 220));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets(
    'Given an armed empty-list pull is reversed below the threshold, then it disarms without refreshing',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: AppRefreshIndicator(
              onRefresh: () async => calls += 1,
              child: ListView(
                physics: AppRefreshIndicator.scrollPhysics,
                children: const [AppRefreshAnchor(key: ValueKey('anchor'))],
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(200, 120));
      await gesture.moveBy(const Offset(0, 220));
      await tester.pump();
      final armedGap = tester
          .getSize(find.byKey(const ValueKey('anchor')))
          .height;
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();

      expect(
        tester.getSize(find.byKey(const ValueKey('anchor'))).height,
        lessThan(armedGap),
      );
      await gesture.up();
      await tester.pumpAndSettle();

      expect(calls, 0);
    },
  );

  testWidgets(
    'Given a horizontal scrollable, when dragged, then it does not refresh',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppRefreshIndicator(
              onRefresh: () async => calls += 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: AppRefreshIndicator.scrollPhysics,
                child: const SizedBox(width: 1200, height: 200),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(200, 120));
      await gesture.moveBy(const Offset(-220, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(calls, 0);
    },
  );

  testWidgets(
    'Given a refresh failure, when the return animation finishes, then the indicator closes and reports the failure',
    (tester) async {
      await _pumpRefreshHarness(
        tester,
        onRefresh: () async => throw StateError('offline'),
      );

      await _pullToRefresh(tester);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isA<StateError>());
      expect(find.byType(CustomPaint), findsNothing);
    },
  );

  testWidgets(
    'Given a pending refresh, when the indicator is disposed, then completion does not update a dead widget',
    (tester) async {
      final refresh = Completer<void>();
      await _pumpRefreshHarness(tester, onRefresh: () => refresh.future);

      await _pullToRefresh(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      refresh.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpRefreshHarness(
  WidgetTester tester, {
  required RefreshCallback onRefresh,
  ScrollNotificationPredicate notificationPredicate =
      defaultScrollNotificationPredicate,
}) {
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: AppRefreshIndicator(
          onRefresh: onRefresh,
          notificationPredicate: notificationPredicate,
          child: ListView(
            physics: AppRefreshIndicator.scrollPhysics,
            children: const [AppRefreshAnchor(), SizedBox(height: 1200)],
          ),
        ),
      ),
    ),
  );
}

Future<void> _pullToRefresh(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(200, 120));
  await gesture.moveBy(const Offset(0, 220));
  await tester.pump(const Duration(milliseconds: 300));
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 250));
}
