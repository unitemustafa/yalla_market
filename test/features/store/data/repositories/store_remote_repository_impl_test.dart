import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/address_required_error.dart';
import 'package:yalla_market/features/store/data/repositories/store_remote_repository_impl.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('StoreRemoteRepositoryImpl', () {
    test(
      'loads classifications, markets, and hydrated market products',
      () async {
        final apiClient = FakeApiClient((request) {
          if (request.path == '/home/classifications/') {
            expect(request.method, 'GET');
            expect(request.queryParameters, isNull);
            return {
              'common_market_classifications': [
                {
                  'id': 1,
                  'name': 'Supermarket',
                  'classification_type': 'featured',
                  'market_count': 1,
                },
              ],
              'market_classifications': [
                {
                  'id': 1,
                  'name': 'Supermarket',
                  'classification_type': 'featured',
                  'market_count': 1,
                  'markets': [
                    {
                      'id': 9,
                      'name': 'Fresh Market',
                      'branch': 'Algiers',
                      'status': 'active',
                      'classification_id': 1,
                      'products': [_fullProduct()],
                    },
                  ],
                },
              ],
              'latest_markets': [
                {
                  'id': 10,
                  'name': 'Newest Market',
                  'branch': 'Cairo',
                  'status': 'active',
                  'classification_id': 1,
                  'created_at': '2026-07-13T12:00:00Z',
                  'products': [_fullProduct()],
                },
              ],
            };
          }
          fail('Unexpected request ${request.method} ${request.path}');
        });
        final repository = StoreRemoteRepositoryImpl(apiClient);

        final result = await repository.getStore();

        result.when(
          success: (store) {
            expect(store.commonClassifications.single.name, 'Supermarket');
            expect(store.classifications.single.id, '1');
            expect(store.classifications.single.marketCountLabel, '1 store');
            final market = store.marketsFor('1').single;
            expect(market.name, 'Fresh Market');
            expect(market.products.single.price, '120.00');
            expect(market.products.single.marketId, '9');
            expect(store.latestMarkets.single.name, 'Newest Market');
            expect(
              store.latestMarkets.single.createdAt,
              DateTime.utc(2026, 7, 13, 12),
            );
          },
          failure: (failure) => fail(failure.message),
        );
      },
    );

    test(
      'maps a missing address response to the add address message',
      () async {
        final repository = StoreRemoteRepositoryImpl(
          FakeApiClient((_) => throw _addressRequiredException()),
        );

        final result = await repository.getStore();

        result.when(
          success: (_) => fail('Expected the request to fail.'),
          failure: (failure) => expect(failure.message, addressRequiredMessage),
        );
      },
    );
  });
}

DioException _addressRequiredException() {
  final options = RequestOptions(path: '/home/classifications/');
  return DioException(
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: 400,
      data: {
        'detail':
            'A user address is required before loading market classifications.',
      },
    ),
    type: DioExceptionType.badResponse,
  );
}

Map<String, Object?> _fullProduct() {
  return {
    'id': 42,
    'name': 'Red Apple',
    'description': 'Fresh fruit',
    'image': '',
    'discount': '10.00',
    'category': {'id': 3, 'name': 'Fruit'},
    'market': {'id': 9, 'name': 'Fresh Market', 'classification_id': 1},
    'variants': [
      {'id': 5, 'price': '120.00', 'sku': 'APPLE-1'},
    ],
  };
}
