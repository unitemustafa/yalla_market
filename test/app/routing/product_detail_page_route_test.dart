import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/routing/product_detail_page_route.dart';

void main() {
  for (final reduceMotion in [false, true]) {
    testWidgets(
      'product route respects Android motion settings ($reduceMotion)',
      (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            theme: ThemeData(platform: TargetPlatform.android),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
            home: const Scaffold(body: Text('Catalog')),
          ),
        );
        final route = ProductDetailPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Product')),
        );
        final result = navigator.currentState!.push(route);
        await tester.pumpAndSettle();
        expect(find.text('Product'), findsOneWidget);
        expect(
          route.transitionDuration,
          Duration(milliseconds: reduceMotion ? 0 : 260),
        );
        expect(
          route.reverseTransitionDuration,
          Duration(milliseconds: reduceMotion ? 0 : 220),
        );
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        await result;
        expect(find.text('Catalog'), findsOneWidget);
      },
    );
  }
}
