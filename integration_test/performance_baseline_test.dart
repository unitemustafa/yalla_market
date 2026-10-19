import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards_sliver.dart';
import 'package:yalla_market/features/home/presentation/views/notifications_view.dart';
import 'package:yalla_market/features/navigation/presentation/views/navigation_menu_view.dart';
import 'package:yalla_market/features/search/presentation/cubit/catalog_search_cubit.dart';
import 'package:yalla_market/features/search/presentation/cubit/catalog_search_state.dart';
import 'package:yalla_market/features/search/presentation/views/search_view.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_products_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';
import 'package:yalla_market/features/store/presentation/views/orders/orders_view.dart';
import 'package:yalla_market/features/wishlist/presentation/views/wishlist_view.dart';

import '../test/performance/stress_app.dart';
import '../test/performance/stress_fixtures.dart';
import 'core/scroll_probe.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
  const language = String.fromEnvironment('PERF_LANGUAGE', defaultValue: 'ar');
  const runId = String.fromEnvironment('PERF_RUN_ID', defaultValue: 'local');
  const scope = String.fromEnvironment('PERF_SCOPE', defaultValue: 'all');
  const hz = int.fromEnvironment('PERF_REFRESH_HZ', defaultValue: 60);
  const selectedCount = int.fromEnvironment('PERF_PRODUCT_COUNT');
  const captureTrace = bool.fromEnvironment('PERF_CAPTURE_TRACE');
  const forceTestSemantics = bool.fromEnvironment('PERF_FORCE_TEST_SEMANTICS');
  const nativeInput = bool.fromEnvironment(
    'PERF_NATIVE_INPUT',
    defaultValue: true,
  );
  binding.shouldPropagateDevicePointerEvents = nativeInput;
  final results = <String, Object?>{};

  Future<void> mount(
    WidgetTester tester,
    StressFixtures fixtures,
    Widget home,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await configureStressApp(fixtures);
    await tester.pumpWidget(StressApp(home: home, languageCode: language));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<void> measure(String name, Future<void> Function() action) async {
    if (captureTrace) {
      await binding.traceAction(action, reportKey: '${name}_trace');
    } else {
      await binding.watchPerformance(action, reportKey: name);
    }
    debugPrint('PERF_MEASURE_DONE $name');
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    if (!nativeInput) {
      await tester.tap(target);
      return;
    }
    final viewId = tester.view.viewId;
    final renderView = binding.renderViews.firstWhere(
      (view) => view.flutterView.viewId == viewId,
    );
    final position = binding.localToGlobal(
      tester.getCenter(target),
      renderView,
    );
    binding.handlePointerEventForSource(
      PointerDownEvent(pointer: 1, position: position, viewId: viewId),
      source: TestBindingEventSource.device,
    );
    await Future<void>.delayed(const Duration(milliseconds: 16));
    binding.handlePointerEventForSource(
      PointerUpEvent(pointer: 1, position: position, viewId: viewId),
      source: TestBindingEventSource.device,
    );
  }

  Finder vertical() => find
      .byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      )
      .first;

  Future<void> scroll(WidgetTester tester) async {
    final motion = await scrollProbe(tester);
    final count = (results['scroll_motion_windows'] as int? ?? 0) + 1;
    results['scroll_motion_windows'] = count;
    results['scroll_motion_$count'] = motion;
  }

  testWidgets(
    'physical Android customer UI baseline',
    (tester) async {
      expect(
        kProfileMode,
        isTrue,
        reason: 'Use flutter drive --profile on a physical Android',
      );
      expect(defaultTargetPlatform, TargetPlatform.android);
      expect(const bool.fromEnvironment('PERFORMANCE_TEST_BUILD'), isTrue);
      binding.reportData = {
        'schema_version': 1,
        'run_id': runId,
        'mode': 'profile',
        'refresh_hz': hz,
        'language': language,
        'scope': scope,
        'completed': false,
        'scroll_protocol': 'edge_reversal_with_motion_validation_v2',
        'trace_diagnostic': captureTrace,
        'input_route': nativeInput ? 'device' : 'test',
        'test_forced_semantics': forceTestSemantics,
        'data_source': 'synthetic_repositories',
        'image_source': StressFixtures.imageBaseUrl.isEmpty
            ? 'bundled_repeated'
            : 'network_fixture',
        'limitations': [
          'Not production startup/API latency',
          'Category taps use the recorded input route; scroll uses test gestures',
          'Semantics overhead follows the recorded test/platform configuration',
        ],
      };
      addTearDown(() async {
        binding.reportData!['observations'] = results;
        AuthGuard.clearAuthentication();
        await sl.reset();
      });

      if (scope == 'all' ||
          scope == 'store' ||
          scope == 'category' ||
          scope == 'browse_search') {
        for (final count
            in selectedCount > 0 ? [selectedCount] : [100, 1000, 10000]) {
          final fixtures = StressFixtures(productCount: count);
          await mount(
            tester,
            fixtures,
            const BrandProductsView(
              brand: 'Stress',
              logo: '',
              productCount: '',
              classificationId: 'stress',
              marketId: '1',
            ),
          );
          final cards = find.byType(ProductCardsSliver<ProductData>);
          expect(cards, findsOneWidget);
          final cubit = tester.element(cards).read<StoreProductsCubit>();
          results['store_${count}_initial_products'] =
              cubit.state.products.length;
          for (var repeat = 1; scope != 'category' && repeat <= 3; repeat++) {
            await measure(
              'store_${count}_scroll_$repeat',
              () => scroll(tester),
            );
            results['store_${count}_loaded_$repeat'] =
                cubit.state.products.length;
            expect(
              cubit.state.products.map((p) => p.id).toSet().length,
              cubit.state.products.length,
            );
            expect(cubit.state.moreError, isNull);
            results['store_${count}_visible_cards_$repeat'] = find
                .byType(ProductCardVertical)
                .evaluate()
                .length;
          }
          for (var repeat = 1; repeat <= 3; repeat++) {
            final samples = <int>[];
            await measure('store_${count}_category_$repeat', () async {
              for (var change = 0; change < 20; change++) {
                tester.state<ScrollableState>(vertical()).position.jumpTo(0);
                await tester.pumpAndSettle();
                final target = find.byKey(
                  ValueKey(
                    'store_subcategory_${change.isEven ? 'odd' : 'even'}',
                  ),
                );
                await tester.ensureVisible(target);
                final watch = Stopwatch()..start();
                await tap(tester, target);
                await tester.pumpAndSettle();
                watch.stop();
                samples.add(watch.elapsedMicroseconds);
                expect(cubit.state.error, isNull);
                expect(cubit.state.products, isNotEmpty);
                expect(
                  cubit.state.products.every(
                    (product) =>
                        product.subcategoryId ==
                        (change.isEven ? 'odd' : 'even'),
                  ),
                  isTrue,
                  reason: 'The category tap must change the displayed results',
                );
              }
            });
            results['store_${count}_category_us_$repeat'] = samples;
          }
        }
      }

      final fixtures = StressFixtures();
      if (scope == 'all' || scope == 'lists') {
        for (final entry in <String, Widget>{
          'home': const NavigationMenuView(),
          'wishlist': const WishlistView(),
          'notifications': const NotificationsView(),
          'orders': const OrdersView(),
        }.entries) {
          await mount(tester, fixtures, entry.value);
          for (var repeat = 1; repeat <= 3; repeat++) {
            await measure('${entry.key}_scroll_$repeat', () => scroll(tester));
          }
        }
      }
      if (scope == 'all' ||
          scope == 'search' ||
          scope == 'browse_search' ||
          scope == 'search_navigation') {
        await mount(
          tester,
          fixtures,
          BlocProvider(
            create: (_) => sl<CatalogSearchCubit>(),
            child: const SearchView(),
          ),
        );
        final searchCubit = tester
            .element(find.byType(SearchView))
            .read<CatalogSearchCubit>();
        void enterProfileText(String text) {
          // integration_test leaves the native text channel registered. Its
          // fake test client (-1) is accepted only in debug, not profile.
          tester
              .state<EditableTextState>(find.byType(EditableText).first)
              .updateEditingValue(
                TextEditingValue(
                  text: text,
                  selection: TextSelection.collapsed(offset: text.length),
                ),
              );
        }

        final latencies = <int>[];
        for (var repeat = 0; repeat < 30; repeat++) {
          final watch = Stopwatch()..start();
          final query = repeat.isEven ? 'Product' : 'Product 0';
          enterProfileText(query);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pumpAndSettle();
          expect(searchCubit.state, isA<CatalogSearchReady>());
          expect(searchCubit.state.query, query);
          expect(searchCubit.state.results.products, isNotEmpty);
          watch.stop();
          latencies.add(watch.elapsedMicroseconds);
        }
        results['search_action_us'] = latencies;
        enterProfileText('Product');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(searchCubit.state, isA<CatalogSearchReady>());
        expect(
          searchCubit.state.results.products.length,
          greaterThanOrEqualTo(30),
        );
        results['search_scroll_initial_products'] =
            searchCubit.state.results.products.length;
        results['search_input_method'] = 'EditableTextState.updateEditingValue';
        for (var repeat = 1; repeat <= 3; repeat++) {
          await measure('search_scroll_$repeat', () => scroll(tester));
        }
      }
      if (scope == 'all' ||
          scope == 'navigation' ||
          scope == 'soak' ||
          scope == 'search_navigation') {
        await mount(tester, fixtures, const NavigationMenuView());
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        final latencies = <int>[];
        final duration = scope == 'soak'
            ? const Duration(minutes: 30)
            : Duration.zero;
        final session = Stopwatch()..start();
        var cycles = 0;
        do {
          final watch = Stopwatch()..start();
          unawaited(
            navigator.pushNamed(
              AppRoutes.productDetail,
              arguments: const ProductDetailRouteArgs(
                productId: '1',
                title: 'Product',
                brand: 'Stress',
                price: '10',
                image: '',
              ),
            ),
          );
          await tester.pumpAndSettle();
          watch.stop();
          latencies.add(watch.elapsedMicroseconds);
          navigator.pop();
          await tester.pumpAndSettle();
          cycles++;
        } while (cycles < 30 || session.elapsed < duration);
        results['product_open_us'] = latencies;
        results['navigation_cycles'] = cycles;
        // RSS is descriptive; this is NOT a heap snapshot or a leak diagnosis.
        results['end_rss_bytes'] = ProcessInfo.currentRss;
        results['end_image_cache_bytes'] =
            PaintingBinding.instance.imageCache.currentSizeBytes;
      }
      expect(tester.takeException(), isNull);
      binding.reportData!['completed'] = true;
    },
    timeout: const Timeout(Duration(minutes: 60)),
    semanticsEnabled: forceTestSemantics,
  );
}
