import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/visible_work.dart';
import 'package:yalla_market/core/presentation/media/media_route_observer_scope.dart';

void main() {
  testWidgets(
    'work pauses for hidden tabs, covered routes and background then resumes',
    (tester) async {
      final observer = RouteObserver<ModalRoute<dynamic>>();
      final navigator = GlobalKey<NavigatorState>();
      var active = true;
      var visible = false;
      var signaled = false;
      late StateSetter change;
      await tester.pumpWidget(
        MediaRouteObserverScope(
          observer: observer,
          child: MaterialApp(
            navigatorKey: navigator,
            navigatorObservers: [observer],
            home: StatefulBuilder(
              builder: (context, setState) {
                change = setState;
                return TickerMode(
                  enabled: active,
                  child: VisibleWork(
                    onVisibilityChanged: (value) => signaled = value,
                    builder: (context, value) {
                      visible = value;
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      expect(visible, isTrue);
      change(() => active = false);
      await tester.pump();
      expect(visible, isFalse);
      change(() => active = true);
      await tester.pump();
      expect(visible, isTrue);
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pumpAndSettle();
      expect(visible, isFalse);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(visible, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(signaled, isFalse);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(visible, isTrue);
    },
  );
}
