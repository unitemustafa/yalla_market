import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';

import 'stress_fixtures.dart';

void main() {
  for (final count in [100, 1000, 10000]) {
    test(
      'records synthetic storefront payload/decode cost for $count products',
      () {
        final raw = jsonEncode(
          StressFixtures(productCount: count).storefrontPayload,
        );
        final measurements = <int>[];
        for (var repeat = 0; repeat < 3; repeat++) {
          final watch = Stopwatch()..start();
          final market = StoreMarketData.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
          watch.stop();
          expect(market.products, hasLength(count));
          measurements.add(watch.elapsedMicroseconds);
        }
        measurements.sort();
        // This is host/debug evidence, never a physical-device performance pass.
        // ignore: avoid_print
        print(
          jsonEncode({
            'products': count,
            'bytes': utf8.encode(raw).length,
            'decode_median_us': measurements[1],
            'mode': 'host_test',
          }),
        );
      },
    );
  }
}
