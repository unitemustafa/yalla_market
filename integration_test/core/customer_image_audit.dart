import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';

import '../../test/performance/customer_audit_scenarios.dart';
import '../../test/performance/stress_app.dart';
import '../../test/performance/stress_fixtures.dart';

/// Exercise the real card image provider with a repeatable loopback transport.
/// A fresh port plus path gives each pair new managed disk/memory cache keys.
Future<void> runCustomerImageAudit(
  WidgetTester tester,
  AuditMeasure measure,
) async {
  final body = await rootBundle.load(
    'assets/images/onboarding/onboarding_products.webp',
  );
  final bytes = body.buffer.asUint8List(body.offsetInBytes, body.lengthInBytes);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final requests = <String, int>{};
  final runId = DateTime.now().microsecondsSinceEpoch;
  final stream = server.listen((request) async {
    requests.update(request.uri.path, (count) => count + 1, ifAbsent: () => 1);
    await Future<void>.delayed(const Duration(milliseconds: 75));
    request.response
      ..headers.contentType = ContentType('image', 'webp')
      ..headers.set(HttpHeaders.cacheControlHeader, 'max-age=3600')
      ..contentLength = bytes.length
      ..add(bytes);
    await request.response.close();
  });
  const gridKey = ValueKey('image-audit-grid');
  const count = 6;
  final fixtures = StressFixtures(productCount: count, listCount: count);
  String path(int iteration, int index) => '/$runId/$iteration/$index.webp';
  int hits(int iteration) => List.generate(
    count,
    (index) => requests[path(iteration, index)] ?? 0,
  ).fold(0, (total, value) => total + value);

  Future<void> prepare(int _) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await configureStressApp(fixtures);
  }

  Future<void> show(int iteration) async {
    await tester.pumpWidget(
      StressApp(
        home: Scaffold(
          body: Center(
            child: Wrap(
              key: gridKey,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < count; i++)
                  SizedBox(
                    width: 100,
                    height: 188,
                    child: ProductCardVertical(
                      productId: 'image-audit-$i',
                      title: 'Fixture $i',
                      brand: 'Fixture',
                      price: '10',
                      image:
                          'http://127.0.0.1:${server.port}${path(iteration, i)}',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final images = find.descendant(
      of: find.byKey(gridKey),
      matching: find.byType(RawImage),
    );
    final deadline = Stopwatch()..start();
    while (tester
            .widgetList<RawImage>(images)
            .where((image) => image.image != null)
            .length <
        count) {
      if (deadline.elapsed > const Duration(seconds: 10)) {
        fail('The six loopback images did not decode.');
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
  }

  try {
    await measure('image_grid_cold', (iteration) async {
      expect(hits(iteration), 0);
      await show(iteration);
      expect(hits(iteration), count);
    }, prepare: prepare);
    await measure('image_grid_warm', (iteration) async {
      final initial = hits(iteration);
      expect(initial, count);
      await show(iteration);
      expect(hits(iteration), initial);
    }, prepare: prepare);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    AuthGuard.clearAuthentication();
    await sl.reset();
    await server.close(force: true);
    await stream.cancel();
  }
}
