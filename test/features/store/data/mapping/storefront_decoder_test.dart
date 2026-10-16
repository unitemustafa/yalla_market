import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/domain/computation_executor.dart';
import 'package:yalla_market/features/store/data/mapping/storefront_decoder.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';

void main() {
  group('StorefrontDecoder', () {
    test('maps a storefront payload through the supplied executor', () async {
      final executor = _RecordingExecutor();
      final decoder = StorefrontDecoder(executor: executor);

      final market = await decoder.decode(_payload());

      expect(market, isA<StoreMarketData>());
      expect(market.id, '9');
      expect(market.name, 'Fresh Market');
      expect(market.products.single.id, '42');
      expect(market.products.single.price, '120.00');
      expect(executor.backgroundRequests, [false]);
    });

    test('uses background execution for a large storefront payload', () async {
      final executor = _RecordingExecutor();
      final decoder = StorefrontDecoder(executor: executor);
      final payload = _payload()
        ..['products'] = List.generate(1000, (_) => _product());

      final market = await decoder.decode(payload);

      expect(market.products, hasLength(1000));
      expect(executor.backgroundRequests, [true]);
    });
  });
}

Map<String, dynamic> _payload() => {
  'id': 9,
  'name': 'Fresh Market',
  'products': [_product()],
};

Map<String, Object?> _product() => {
  'id': 42,
  'name': 'Red Apple',
  'market': {'id': 9, 'name': 'Fresh Market'},
  'variants': [
    {'id': 5, 'price': '120.00'},
  ],
};

class _RecordingExecutor implements ComputationExecutor {
  final backgroundRequests = <bool>[];

  @override
  Future<R> run<Q, R>(
    R Function(Q) computation,
    Q input, {
    required bool background,
  }) async {
    backgroundRequests.add(background);
    return computation(input);
  }
}
