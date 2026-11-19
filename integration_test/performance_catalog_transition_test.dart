import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/app/routing/catalog_route_container.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';
import 'package:yalla_market/features/store/presentation/views/product_detail_view.dart';

import '../test/performance/stress_app.dart';
import '../test/performance/stress_fixtures.dart';

/// Profile the actual catalog routes using the isolated .performance package.
/// Bundled images and synthetic repositories exclude production API/CDN latency.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  testWidgets('product and market open/close transitions', (tester) async {
    expect(kProfileMode, isTrue);
    expect(const bool.fromEnvironment('PERFORMANCE_TEST_BUILD'), isTrue);
    binding.reportData = {
      'completed': false,
      'data_source': 'synthetic_repositories_and_bundled_images',
    };
    final fixtures = StressFixtures(productCount: 60, listCount: 10);
    await configureStressApp(fixtures);
    addTearDown(() async {
      AuthGuard.clearAuthentication();
      await sl.reset();
    });
    final product = fixtures.products.first;
    final routes = {
      'product': RouteSettings(
        name: AppRoutes.productDetail,
        arguments: ProductDetailRouteArgs(
          productId: product.id,
          image: product.image,
          title: product.title,
          brand: product.brand,
          price: product.price,
        ),
      ),
      'market': const RouteSettings(
        name: AppRoutes.brandProducts,
        arguments: BrandProductsRouteArgs(
          brand: 'Stress',
          logo: '',
          productCount: '60',
          marketId: '1',
          classificationId: 'stress',
        ),
      ),
    };
    await tester.pumpWidget(
      StressApp(
        languageCode: 'ar',
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in routes.entries)
                  SizedBox(
                    width: 180,
                    height: 120,
                    child: CatalogRouteContainer(
                      settings: entry.value,
                      closedBuilder: (context, open) => TextButton(
                        key: ValueKey('open-${entry.key}'),
                        onPressed: open,
                        child: Text(entry.key),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final name in routes.keys) {
      for (var repeat = 0; repeat < 3; repeat++) {
        await binding.watchPerformance(() async {
          await tester.tap(find.byKey(ValueKey('open-$name')));
          await tester.pumpAndSettle();
        }, reportKey: '${name}_open_$repeat');
        final page = name == 'product'
            ? find.byType(ProductDetailView)
            : find.byType(BrandProductsView);
        expect(page, findsOneWidget);
        await binding.watchPerformance(() async {
          Navigator.of(tester.element(page)).pop();
          await tester.pumpAndSettle();
        }, reportKey: '${name}_close_$repeat');
        expect(page, findsNothing);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    binding.reportData!['completed'] = true;
  });
}
