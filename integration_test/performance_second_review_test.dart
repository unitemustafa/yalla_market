import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/features/offers/domain/entities/offer_data.dart';
import 'package:yalla_market/features/offers/presentation/widgets/promo_slider.dart';

import '../test/performance/stress_app.dart';
import '../test/performance/stress_fixtures.dart';
import 'core/scroll_probe.dart';

/// Physical-device rendering check using synthetic repositories and local assets.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
  testWidgets('physical Android offer with 300 products', (tester) async {
    expect(kProfileMode, isTrue);
    expect(const bool.fromEnvironment('PERFORMANCE_TEST_BUILD'), isTrue);
    binding.reportData = {
      'completed': false,
      'mode': 'profile',
      'data_source': 'synthetic_repositories',
      'images': 'bundled_repeated',
      'limitations': [
        'Rendering measurement excludes production API/CDN latency',
      ],
    };
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      AuthGuard.clearAuthentication();
      await sl.reset();
    });
    final fixtures = StressFixtures(productCount: 300, listCount: 0);
    await configureStressApp(fixtures);
    final offers = List.generate(
      50,
      (index) => OfferData(
        id: '$index',
        title: 'Offer $index',
        description: 'Synthetic offer',
        image: AppAssets.defaultOffer,
        type: 'discount',
        discount: '10',
        startsAt: null,
        endsAt: DateTime(2100),
        marketName: 'Fixture',
        products: index == 0 ? fixtures.products : const [],
      ),
    );
    await tester.pumpWidget(
      StressApp(
        home: Scaffold(body: PromoSlider(offers: offers)),
        languageCode: 'ar',
      ),
    );
    await tester.pumpAndSettle();
    final indicators = find.byType(AnimatedContainer).evaluate().length;
    expect(indicators, lessThanOrEqualTo(9));
    expect(find.text('1/50'), findsOneWidget);
    await binding.watchPerformance(() async {
      await tester.tap(find.byKey(const ValueKey('promo_offer_card')).first);
      await tester.pumpAndSettle();
    }, reportKey: 'offer_300_open');
    final initialRows = find
        .byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_OfferProductRow',
        )
        .evaluate()
        .length;
    expect(initialRows, inInclusiveRange(1, 20));
    Map<String, num>? motion;
    await binding.watchPerformance(() async {
      motion = await scrollProbe(tester);
    }, reportKey: 'offer_300_scroll');
    binding.reportData!.addAll({
      'initial_rows': initialRows,
      'indicators': indicators,
      'motion': motion,
      'rss_bytes': ProcessInfo.currentRss,
      'image_cache_bytes': PaintingBinding.instance.imageCache.currentSizeBytes,
      'completed': true,
    });
    debugPrint('PERF_REVIEW_DONE offer_300');
  });
}
