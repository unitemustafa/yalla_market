import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';
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

  testWidgets('isolated 1000-store profile review', (tester) async {
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
    for (var repeat = 1; repeat <= 2; repeat++) {
      await measure('stores_1000_scroll_$repeat', () async {
        observations['stores_motion_$repeat'] = await scrollProbe(
          tester,
        );
      });
    }
    memory('stores_1000');
    binding.reportData!['completed'] = true;
  });
}
