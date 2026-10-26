import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';
import 'package:yalla_market/features/store/presentation/views/checkout_view.dart';
import 'package:yalla_market/features/store/presentation/widgets/store_market_card.dart';
import '../test/performance/stress_app.dart';
import '../test/performance/stress_fixtures.dart';
import 'core/scroll_probe.dart';

/// Run against both baseline and changed app code with this identical harness.
/// Uses the separate .performance package and synthetic repositories only.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
  const run = String.fromEnvironment('PERF_RUN_ID', defaultValue: 'local');
  final observations = <String, Object?>{};
  Future<void> mount(
    WidgetTester tester,
    StressFixtures fixtures,
    Widget home,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await configureStressApp(fixtures);
    await tester.pumpWidget(StressApp(home: home, languageCode: 'ar'));
    await tester.pumpAndSettle();
  }

  void memory(String name) {
    final cache = PaintingBinding.instance.imageCache;
    observations['${name}_memory'] = {
      'rss_bytes': ProcessInfo.currentRss,
      'peak_rss_bytes': ProcessInfo.maxRss,
      'image_cache_bytes': cache.currentSizeBytes,
      'live_images': cache.liveImageCount,
    };
  }

  Future<void> measure(String name, Future<void> Function() action) async {
    await binding.watchPerformance(action, reportKey: name);
    debugPrint('PERF_REVIEW_DONE $name');
  }

  testWidgets('physical Android catalog and checkout review', (tester) async {
    expect(kProfileMode, isTrue);
    expect(defaultTargetPlatform, TargetPlatform.android);
    expect(const bool.fromEnvironment('PERFORMANCE_TEST_BUILD'), isTrue);
    binding.reportData = {
      'schema_version': 1,
      'run_id': run,
      'mode': 'profile',
      'completed': false,
      'data_source': 'synthetic_repositories',
      'images': StressFixtures.imageBaseUrl.isEmpty
          ? 'bundled_repeated'
          : 'network_fixture',
      'limitations': [
        'Local fixture image transport, not production CDN/API latency',
        'Eight image contents cycle through unique URL cache keys',
        'RSS includes caches; not a retained-heap leak test',
      ],
    };
    addTearDown(() async {
      binding.reportData!['observations'] = observations;
      AuthGuard.clearAuthentication();
      await sl.reset();
    });
    for (final count in [300, 1000]) {
      final fixtures = StressFixtures(
        productCount: count,
        listCount: 1000,
        imageNamespace: run,
      );
      await measure(
        'products_${count}_open',
        () => mount(
          tester,
          fixtures,
          const BrandProductsView(
            brand: 'Stress',
            logo: '',
            productCount: '',
            classificationId: 'stress',
            marketId: '1',
          ),
        ),
      );
      observations['products_${count}_initial_cards'] = find
          .byType(ProductCardVertical)
          .evaluate()
          .length;
      expect(
        find.byType(ProductCardVertical).evaluate().length,
        inInclusiveRange(1, 30),
      );
      memory('products_$count');
      for (var repeat = 1; repeat <= 2; repeat++) {
        await measure('products_${count}_scroll_$repeat', () async {
          observations['products_${count}_motion_$repeat'] = await scrollProbe(
            tester,
          );
        });
      }
    }
    final fixtures = StressFixtures(
      productCount: 1000,
      listCount: 1000,
      imageNamespace: run,
    );
    await measure(
      'stores_1000_open',
      () => mount(
        tester,
        fixtures,
        const BrandProductsView(
          brand: 'Stress',
          logo: '',
          productCount: '1000',
          classificationId: 'stress',
        ),
      ),
    );
    observations['stores_1000_initial_cards'] = find
        .byType(StoreMarketCard)
        .evaluate()
        .length;
    expect(
      find.byType(StoreMarketCard).evaluate().length,
      inInclusiveRange(1, 20),
    );
    await measure('stores_1000_scroll', () async {
      observations['stores_motion'] = await scrollProbe(tester);
    });
    memory('stores_1000');
    await measure('checkout_300_open', () async {
      await mount(
        tester,
        fixtures,
        const CheckoutView(useDemoRepositories: true),
      );
      final cart = tester.element(find.byType(CheckoutView)).read<CartCubit>();
      cart.emit(
        fixtures.products
            .take(300)
            .map(
              (p) => CartItemData(
                id: p.id,
                productId: p.id,
                variantId: p.defaultVariantId,
                image: p.image,
                title: p.title,
                brand: p.brand,
                price: p.priceValue,
                quantity: 1,
              ),
            )
            .toList(growable: false),
      );
      await tester.pumpAndSettle();
    });
    observations['checkout_300_initial_cards'] = find
        .byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_CheckoutItemCard',
        )
        .evaluate()
        .length;
    memory('checkout_300');
    await measure('checkout_300_scroll', () async {
      observations['checkout_motion'] = await scrollProbe(tester);
    });
    binding.reportData!['completed'] = true;
  });
}
