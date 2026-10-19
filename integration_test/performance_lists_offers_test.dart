import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/widgets/brands/category_tile.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/features/home/presentation/views/notifications_view.dart';
import 'package:yalla_market/features/navigation/presentation/views/navigation_menu_view.dart';
import 'package:yalla_market/features/offers/domain/entities/offer_data.dart';
import 'package:yalla_market/features/offers/domain/repositories/offer_repository.dart';
import 'package:yalla_market/features/offers/domain/usecases/get_offers_usecase.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';
import 'package:yalla_market/features/store/presentation/views/orders/orders_view.dart';
import 'package:yalla_market/features/store/presentation/views/orders/widgets/order_list_item.dart';
import 'package:yalla_market/features/wishlist/presentation/views/wishlist_view.dart';

import '../test/performance/stress_app.dart';
import '../test/performance/stress_fixtures.dart';

/// Profile-only physical-device diagnostic for resident list widgets.
///
/// This intentionally reports observed RSS/cache and live widget counts. It
/// does not infer heap retention or classify any measurement as a memory leak.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final observations = <String, Object?>{};
  const forcedSemantics = bool.fromEnvironment('PERF_FORCE_TEST_SEMANTICS');
  const residentListsOnly = bool.fromEnvironment('PERF_RESIDENT_LISTS_ONLY');

  Future<void> configureOffers(StressFixtures fixtures) async {
    await configureStressApp(fixtures);
    await sl.unregister<OfferRepository>();
    await sl.unregister<GetOffersUseCase>();
    sl.registerSingleton<OfferRepository>(
      _OfferProbeRepository(_offers(fixtures, count: 10)),
    );
    sl.registerLazySingleton(() => GetOffersUseCase(sl<OfferRepository>()));
  }

  Future<void> mount(
    WidgetTester tester,
    StressFixtures fixtures,
    Widget home,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await configureOffers(fixtures);
    await tester.pumpWidget(const StressApp(home: SizedBox.shrink()));
    await tester.pumpWidget(StressApp(home: home));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Map<String, int> memorySample() => {
    'rss_bytes': ProcessInfo.currentRss,
    'image_cache_bytes': PaintingBinding.instance.imageCache.currentSizeBytes,
    'image_cache_entries': PaintingBinding.instance.imageCache.currentSize,
  };

  Future<ScrollPosition> readyScrollPosition(
    WidgetTester tester,
    Finder scrollable,
  ) async {
    final position = tester.state<ScrollableState>(scrollable).position;
    for (var attempt = 0; attempt < 20; attempt++) {
      if (position.hasContentDimensions) return position;
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(position.hasContentDimensions, isTrue);
    return position;
  }

  Future<Map<String, num>> controlledFlingProbe(WidgetTester tester) async {
    Finder vertical() => find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;

    var forward = true;
    var moving = 0;
    var reversals = 0;
    var distance = 0.0;
    final watch = Stopwatch()..start();
    for (var fling = 0; fling < 10; fling++) {
      final position = await readyScrollPosition(tester, vertical());
      expect(position.maxScrollExtent, greaterThan(position.minScrollExtent));
      if (forward && position.pixels >= position.maxScrollExtent - 1) {
        forward = false;
        reversals++;
      } else if (!forward && position.pixels <= position.minScrollExtent + 1) {
        forward = true;
        reversals++;
      }
      final before = position.pixels;
      await tester.fling(vertical(), Offset(0, forward ? -600 : 600), 1400);
      await tester.pumpAndSettle();
      final delta = (position.pixels - before).abs();
      distance += delta;
      if (delta > 1) moving++;
    }
    expect(moving, greaterThanOrEqualTo(8));
    return {
      'elapsed_ms': watch.elapsedMilliseconds,
      'flings': 10,
      'moving_flings': moving,
      'distance_px': distance,
      'edge_reversals': reversals,
    };
  }

  /// Exercises the production promo PageView, retaining motion for the full
  /// window and recording page-offset changes rather than list scrolling.
  Future<Map<String, num>> offerPagingProbe(WidgetTester tester) async {
    Finder horizontal() => find.descendant(
      of: find.byKey(const ValueKey('store_offer_section')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            (widget.axisDirection == AxisDirection.left ||
                widget.axisDirection == AxisDirection.right),
      ),
    );

    final watch = Stopwatch()..start();
    var forward = true;
    var swipes = 0;
    var movingSwipes = 0;
    var pageChanges = 0;
    var reversals = 0;
    var distance = 0.0;
    var previousPage = -1;
    while (watch.elapsed < const Duration(seconds: 30)) {
      final position = await readyScrollPosition(tester, horizontal());
      expect(position.maxScrollExtent, greaterThan(position.minScrollExtent));
      if (forward && position.pixels >= position.maxScrollExtent - 1) {
        forward = false;
        reversals++;
      } else if (!forward && position.pixels <= position.minScrollExtent + 1) {
        forward = true;
        reversals++;
      }
      final before = position.pixels;
      final rtl = position.axisDirection == AxisDirection.left;
      final dx = (forward ? -360.0 : 360.0) * (rtl ? -1 : 1);
      await tester.fling(horizontal(), Offset(dx, 0), 1200);
      await tester.pumpAndSettle();
      final after = position.pixels;
      final delta = (after - before).abs();
      distance += delta;
      if (delta > 1) movingSwipes++;
      final page = (after / position.viewportDimension).round();
      if (previousPage >= 0 && page != previousPage) pageChanges++;
      previousPage = page;
      swipes++;
    }
    expect(movingSwipes, greaterThanOrEqualTo(5));
    expect(pageChanges, greaterThanOrEqualTo(5));
    return {
      'elapsed_ms': watch.elapsedMilliseconds,
      'swipes': swipes,
      'moving_swipes': movingSwipes,
      'page_changes': pageChanges,
      'distance_px': distance,
      'edge_reversals': reversals,
    };
  }

  Future<void> diagnoseList({
    required WidgetTester tester,
    required StressFixtures fixtures,
    required String name,
    required Widget home,
    required int Function() residentItemCount,
  }) async {
    await mount(tester, fixtures, home);
    final before = memorySample();
    final residentBefore = residentItemCount();
    final motion = await controlledFlingProbe(tester);
    final residentAfter = residentItemCount();
    expect(tester.takeException(), isNull);
    observations[name] = {
      'fixture_item_count': fixtures.listCount,
      'item_widget_count_kind': 'resident_live_element_count',
      'resident_item_widgets_before': residentBefore,
      'resident_item_widgets_after': residentAfter,
      'lifetime_item_builds': 'not_instrumented',
      'memory_before': before,
      'memory_after': memorySample(),
      'scroll_motion': motion,
    };
    binding.reportData!['observations'] = observations;
  }

  testWidgets(
    'physical profile offers and long-list residency probe',
    (tester) async {
      expect(kProfileMode, isTrue, reason: 'Use flutter drive --profile.');
      expect(defaultTargetPlatform, TargetPlatform.android);
      expect(const bool.fromEnvironment('PERFORMANCE_TEST_BUILD'), isTrue);
      expect(forcedSemantics, isFalse);
      binding.framePolicy =
          LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
      binding.reportData = {
        'schema_version': 1,
        'scope': 'physical_offers_and_long_list_residency',
        'completed': false,
        'test_forced_semantics': forcedSemantics,
        'resident_lists_only': residentListsOnly,
        'observations': observations,
        'limitations': [
          'Synthetic repositories; no production API or startup measurement.',
          'RSS and image-cache values are descriptive samples, not leak diagnoses.',
          'Resident widget counts are live elements, not lifetime build counts.',
        ],
      };
      addTearDown(() async {
        AuthGuard.clearAuthentication();
        await sl.reset();
      });

      final fixtures = StressFixtures();
      if (!residentListsOnly) {
        await mount(
          tester,
          fixtures,
          const BrandProductsView(
            brand: 'Stress',
            logo: '',
            productCount: '10000',
            classificationId: 'stress',
            marketId: '1',
          ),
        );
        expect(
          find.byKey(const ValueKey('store_offer_section')),
          findsOneWidget,
        );
        final offerBefore = memorySample();
        final offerMotion = <Map<String, num>>[];
        for (var pass = 1; pass <= 3; pass++) {
          final reportKey = 'offers_page_round_$pass';
          await binding.watchPerformance(
            () async => offerMotion.add(await offerPagingProbe(tester)),
            reportKey: reportKey,
          );
          expect(tester.takeException(), isNull);
          observations['offers'] = {
            'fixture_offer_count': 10,
            'fixture_count_note':
                'Ten offers match the production non-virtualized indicator.',
            'offer_surface': 'BrandProductsView.StoreOfferSection',
            'item_widget_count_kind': 'resident_live_element_count',
            'resident_product_cards_after': find
                .byType(ProductCardVertical)
                .evaluate()
                .length,
            'lifetime_item_builds': 'not_instrumented',
            'memory_before': offerBefore,
            'memory_after': memorySample(),
            'page_motion_windows': offerMotion,
            'frame_timing_report_keys': List.generate(
              pass,
              (index) => 'offers_page_round_${index + 1}',
            ),
          };
          binding.reportData!['observations'] = observations;
        }
      } else {
        observations['offers'] = {
          'skipped': true,
          'skip_reason': 'PERF_RESIDENT_LISTS_ONLY=true',
        };
        binding.reportData!['observations'] = observations;
      }

      await diagnoseList(
        tester: tester,
        fixtures: fixtures,
        name: 'home',
        home: const NavigationMenuView(),
        residentItemCount: () =>
            find.byType(CategoryTile).evaluate().length +
            find.byType(ProductCardVertical).evaluate().length,
      );
      await diagnoseList(
        tester: tester,
        fixtures: fixtures,
        name: 'wishlist',
        home: const WishlistView(),
        residentItemCount: () =>
            find.byType(ProductCardVertical).evaluate().length,
      );
      await diagnoseList(
        tester: tester,
        fixtures: fixtures,
        name: 'notifications',
        home: const NotificationsView(),
        residentItemCount: () => find.byType(Dismissible).evaluate().length,
      );
      await diagnoseList(
        tester: tester,
        fixtures: fixtures,
        name: 'orders',
        home: const OrdersView(),
        residentItemCount: () => find.byType(OrderListItem).evaluate().length,
      );

      expect(tester.takeException(), isNull);
      binding.reportData!['completed'] = true;
    },
    timeout: const Timeout(Duration(minutes: 12)),
    semanticsEnabled: forcedSemantics,
  );
}

class _OfferProbeRepository implements OfferRepository {
  const _OfferProbeRepository(this._items);

  final List<OfferData> _items;

  @override
  Future<ApiResult<List<OfferData>>> getOffers() async =>
      ApiResult.success(_items);
}

List<OfferData> _offers(StressFixtures fixtures, {required int count}) {
  return List<OfferData>.unmodifiable(
    List.generate(
      count,
      (index) => OfferData(
        id: 'performance-offer-${index + 1}',
        title: 'Performance offer ${index + 1}',
        description: 'Deterministic storefront offer fixture.',
        image: fixtures.image(index),
        type: 'product',
        discount: '${10 + index % 30}',
        startsAt: DateTime.utc(2026, 1, 1),
        endsAt: DateTime.utc(2099, 1, 1),
        marketId: '1',
        marketClassificationId: 'stress',
        marketName: 'Store 0',
        products: [fixtures.products[index % fixtures.products.length]],
      ),
    ),
  );
}
