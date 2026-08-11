import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/coordinators/app_deep_link_coordinator.dart';
import 'package:yalla_market/app/routing/app_navigator.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';

void main() {
  testWidgets('opens a pending product link after startup routes finish', (
    tester,
  ) async {
    final coordinator = AppDeepLinkCoordinator(canOpen: () => true);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppNavigator.key,
        navigatorObservers: [coordinator.routeObserver],
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            if (settings.name == AppRoutes.productDetail) {
              final args = settings.arguments! as ProductDetailRouteArgs;
              return Scaffold(body: Text('product:${args.productId}'));
            }
            return Scaffold(body: Text(settings.name ?? 'unknown'));
          },
        ),
      ),
    );

    coordinator.handleUri(Uri.parse('yallamarket://products/42'));
    await tester.pump();
    expect(find.text('product:42'), findsNothing);

    AppNavigator.key.currentState!.pushReplacementNamed(
      AppRoutes.navigationMenu,
    );
    await tester.pumpAndSettle();

    expect(find.text('product:42'), findsOneWidget);
  });
}
