import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/data/repositories/store_products_remote_repository_impl.dart';
import 'package:yalla_market/features/store/domain/entities/store_product_page.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('StoreProductsRemoteRepositoryImpl', () {
    test(
      'requests a filtered page and maps its products and continuation',
      () async {
        final api = FakeApiClient((request) {
          expect(request.method, 'GET');
          expect(request.path, '/home/markets/7/storefront/products/');
          expect(request.queryParameters, {
            'page': 2,
            'page_size': 30,
            'q': 'apple',
            'sort': 'price_desc',
            'subcategory_id': 'fruit',
          });
          return {
            'count': 61,
            'next': '/api/v1/home/markets/7/storefront/products/?page=3',
            'previous': '/api/v1/home/markets/7/storefront/products/?page=1',
            'results': [_product(id: 12, name: 'Red Apple')],
          };
        });

        final result = await StoreProductsRemoteRepositoryImpl(api).getProducts(
          '7',
          page: 2,
          query: 'apple',
          subcategoryId: 'fruit',
          sort: StoreProductSort.priceDesc,
        );

        result.when(
          success: (page) {
            expect(page.count, 61);
            expect(page.hasMore, isTrue);
            expect(page.products.single.id, '12');
            expect(page.products.single.marketId, '7');
            expect(page.products.single.brand, 'Fresh Market');
          },
          failure: (failure) => fail(failure.message),
        );
      },
    );

    test('omits an empty subcategory and maps the final empty page', () async {
      final api = FakeApiClient((request) {
        expect(request.queryParameters, {
          'page': 1,
          'page_size': 30,
          'q': '',
          'sort': 'name',
        });
        return {'count': 0, 'next': null, 'previous': null, 'results': []};
      });

      final result = await StoreProductsRemoteRepositoryImpl(
        api,
      ).getProducts('7', subcategoryId: '');

      result.when(
        success: (page) {
          expect(page.products, isEmpty);
          expect(page.count, 0);
          expect(page.hasMore, isFalse);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('maps malformed pagination payloads to a typed failure', () async {
      for (final payload in <Map<String, dynamic>>[
        {'count': 1, 'next': null, 'results': 'invalid'},
        {'count': -1, 'next': null, 'results': []},
        {'count': 1, 'next': 2, 'results': []},
        {
          'count': 1,
          'next': null,
          'results': [
            <String, dynamic>{'name': 'Missing id'},
          ],
        },
      ]) {
        final result = await StoreProductsRemoteRepositoryImpl(
          FakeApiClient((_) => payload),
        ).getProducts('7');

        expect(result, isA<ApiFailure<StoreProductPage>>());
        expect(
          (result as ApiFailure<StoreProductPage>).failure,
          isA<UnknownFailure>(),
        );
      }
    });

    test('maps transport failures through the API error handler', () async {
      final options = RequestOptions(
        path: '/home/markets/7/storefront/products/',
      );
      final result = await StoreProductsRemoteRepositoryImpl(
        FakeApiClient(
          (_) => throw DioException(
            requestOptions: options,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ).getProducts('7');

      expect(result, isA<ApiFailure<StoreProductPage>>());
      expect(
        (result as ApiFailure<StoreProductPage>).failure,
        isA<UnauthorizedFailure>(),
      );
    });
  });
}

Map<String, dynamic> _product({required int id, required String name}) => {
  'id': id,
  'name': name,
  'description': 'Fresh product',
  'market': {'id': 7, 'name': 'Fresh Market', 'classification_id': 1},
  'variants': [
    {'id': id * 10, 'price': '10.00'},
  ],
};
