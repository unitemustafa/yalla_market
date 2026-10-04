import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/refresh_on_return.dart';

void main() {
  testWidgets('refreshes after a real page is popped', (tester) async {
    final observer = RouteObserver<PageRoute<dynamic>>();
    final changes = ChangeNotifier();
    var refreshes = 0;
    await tester.pumpWidget(
      _app(
        observer: observer,
        changes: changes,
        onRefresh: () async => refreshes++,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('push-page')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(refreshes, 1);
  });

  testWidgets('does not refresh when a popup dialog is dismissed', (
    tester,
  ) async {
    final observer = RouteObserver<PageRoute<dynamic>>();
    final changes = ChangeNotifier();
    var refreshes = 0;
    await tester.pumpWidget(
      _app(
        observer: observer,
        changes: changes,
        onRefresh: () async => refreshes++,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('show-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(refreshes, 0);
  });

  testWidgets('runs invalidation after returning to a covered page', (
    tester,
  ) async {
    final observer = RouteObserver<PageRoute<dynamic>>();
    final changes = ChangeNotifier();
    var invalidations = 0;
    await tester.pumpWidget(
      _app(
        observer: observer,
        changes: changes,
        onRefresh: () async {},
        onInvalidated: () async => invalidations++,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('push-page')));
    await tester.pumpAndSettle();
    changes.notifyListeners();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(invalidations, 1);
  });

  testWidgets('removes the catalog listener when unmounted', (tester) async {
    final observer = RouteObserver<PageRoute<dynamic>>();
    final changes = ChangeNotifier();
    var refreshes = 0;
    await tester.pumpWidget(
      _app(
        observer: observer,
        changes: changes,
        onRefresh: () async => refreshes++,
      ),
    );
    await tester.pumpWidget(const SizedBox());
    changes.notifyListeners();
    await tester.pump();

    expect(refreshes, 0);
  });

  testWidgets('runs another refresh when invalidated while one is running', (
    tester,
  ) async {
    final observer = RouteObserver<PageRoute<dynamic>>();
    final changes = ChangeNotifier();
    final firstRefresh = Completer<void>();
    var refreshes = 0;
    await tester.pumpWidget(
      _app(
        observer: observer,
        changes: changes,
        onRefresh: () {
          refreshes++;
          return refreshes == 1 ? firstRefresh.future : Future.value();
        },
      ),
    );

    changes.notifyListeners();
    await tester.pump();
    expect(refreshes, 1);
    changes.notifyListeners();
    firstRefresh.complete();
    await tester.pump();
    await tester.pump();

    expect(refreshes, 2);
  });
}

Widget _app({
  required RouteObserver<PageRoute<dynamic>> observer,
  required ChangeNotifier changes,
  required Future<void> Function() onRefresh,
  Future<void> Function()? onInvalidated,
}) {
  return MaterialApp(
    navigatorObservers: [observer],
    home: PageRefreshScope(
      observer: observer,
      catalogChanges: changes,
      child: RefreshOnReturn(
        refreshOnMount: false,
        onRefresh: onRefresh,
        onInvalidated: onInvalidated,
        child: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  key: const ValueKey('push-page'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const Scaffold()),
                  ),
                  child: const Text('Push'),
                ),
                ElevatedButton(
                  key: const ValueKey('show-dialog'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      actions: [
                        TextButton(
                          onPressed: Navigator.of(context).pop,
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Dialog'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
