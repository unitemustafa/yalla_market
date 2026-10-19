import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/features/navigation/presentation/views/navigation_menu_view.dart';

import '../test/performance/stress_app.dart';
import '../test/performance/stress_fixtures.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var phase = 'setup';
  Completer<void>? resume;
  developer.registerExtension('ext.yalla.perf.memory', (
    method,
    parameters,
  ) async {
    if (parameters['continue'] == phase && !(resume?.isCompleted ?? true)) {
      resume!.complete();
    }
    return developer.ServiceExtensionResponse.result(
      jsonEncode({'phase': phase}),
    );
  });
  Future<void> checkpoint(String name) async {
    phase = name;
    resume = Completer<void>();
    debugPrint('PERF_MEMORY_CHECKPOINT $name');
    await resume!.future.timeout(const Duration(minutes: 5));
  }

  testWidgets(
    'separate heap diagnostic and 30 minute customer session',
    (tester) async {
      expect(kProfileMode, isTrue);
      expect(const bool.fromEnvironment('PERFORMANCE_TEST_BUILD'), isTrue);
      await configureStressApp(StressFixtures());
      await tester.pumpWidget(
        const StressApp(home: NavigationMenuView(), languageCode: 'ar'),
      );
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      final rss = <Map<String, Object?>>[];
      Future<void> cycle() async {
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
        navigator.pop();
        await tester.pumpAndSettle();
      }

      for (var i = 0; i < 3; i++) {
        await cycle();
      }
      await checkpoint('baseline');
      for (var i = 0; i < 20; i++) {
        await cycle();
      }
      await checkpoint('after20');
      const minutes = int.fromEnvironment(
        'PERF_SOAK_MINUTES',
        defaultValue: 30,
      );
      final watch = Stopwatch()..start();
      var cycles = 0;
      while (watch.elapsed < Duration(minutes: minutes)) {
        await cycle();
        cycles++;
        rss.add({
          'elapsed_ms': watch.elapsedMilliseconds,
          'rss_bytes': ProcessInfo.currentRss,
          'image_cache_bytes':
              PaintingBinding.instance.imageCache.currentSizeBytes,
        });
        await tester.pump(const Duration(seconds: 2));
      }
      await checkpoint('after_soak');
      phase = 'complete';
      binding.reportData = {
        'schema_version': 1,
        'scope': 'synthetic_memory_diagnostic',
        'completed': true,
        'soak_minutes': minutes,
        'cycles': cycles,
        'rss_samples': rss,
        'limitations': [
          'Forced GC and heap snapshots: excluded from frame acceptance',
          'Repeated bundled image, no API/network coverage',
        ],
      };
      await tester.pumpWidget(const SizedBox.shrink());
      AuthGuard.clearAuthentication();
      await sl.reset();
    },
    timeout: const Timeout(Duration(minutes: 50)),
  );
}
