import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/app_refresh_indicator.dart';

void main() {
  testWidgets('uses the shared home pull-to-refresh configuration', (
    tester,
  ) async {
    var refreshCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppRefreshIndicator(
            onRefresh: () async => refreshCalls += 1,
            child: ListView(
              physics: AppRefreshIndicator.scrollPhysics,
              children: const [SizedBox(height: 900)],
            ),
          ),
        ),
      ),
    );

    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    final list = tester.widget<ListView>(find.byType(ListView));

    expect(indicator.color, isNull);
    expect(indicator.backgroundColor, isNull);
    expect(indicator.displacement, 40);
    expect(indicator.triggerMode, RefreshIndicatorTriggerMode.onEdge);
    expect(list.physics, same(AppRefreshIndicator.scrollPhysics));

    await indicator.onRefresh();
    await tester.pump();
    expect(refreshCalls, 1);
    expect(find.text('Content updated'), findsOneWidget);
  });
}
