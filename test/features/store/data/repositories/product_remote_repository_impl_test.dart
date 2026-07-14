import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/address_required_error.dart';
import 'package:yalla_market/features/store/data/repositories/product_remote_repository_impl.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('ProductRemoteRepositoryImpl', () {
    test(
      'loads full product details from the customer detail endpoint',
      () async {
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'GET');
          expect(request.path, '/home/products/42/');
          return {
            ..._backendProduct(),
            'images': [
              {
                'id': 1,
                'url': 'https://cdn.example.com/apple-primary.png',
                'is_primary': true,
              },
              {
                'id': 2,
                'image': '/media/apple-secondary.png',
                'is_primary': false,
              },
            ],
            'attributes': [
              {
                'id': 3,
                'name': 'Size',
                'options': [
                  {'id': 4, 'value': 'Large'},
                ],
              },
            ],
            'variants': [
              {
                'id': 5,
                'price': '120.00',
                'attribute_values': [
                  {'attribute_name': 'Size', 'option_value': 'Large'},
                ],
              },
            ],
            'additions': [
              {
                'id': 6,
                'name_ar': 'إضافة',
                'price': '10.00',
                'is_active': true,
              },
            ],
          };
        });
        final repository = ProductRemoteRepositoryImpl(apiClient);

        final result = await repository.getProduct('42');

        result.when(
          success: (product) {
            expect(product.id, '42');
            expect(product.description, 'Fresh fruit');
            expect(product.images, hasLength(2));
            expect(product.attributes.single.options.single.value, 'Large');
            expect(product.variants.single.attributeValues, {'Size': 'Large'});
            expect(product.additions.single.id, '6');
          },
          failure: (failure) => fail(failure.message),
        );
      },
    );

    test('searches products through the API contract', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/home/search/');
        expect(request.queryParameters, {'q': 'shoe'});
        return {
          'results': [_backendProduct()],
        };
      });
      final repository = ProductRemoteRepositoryImpl(apiClient);

      final result = await repository.searchProducts(' shoe ');

      result.when(
        success: (products) => expect(products.single.id, '42'),
        failure: (failure) => fail(failure.message),
      );
    });

    test(
      'loads the latest fifteen without forwarding the selected city',
      () async {
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'GET');
          expect(request.path, '/home/products/');
          expect(request.queryParameters, {
            'order_by_latest': true,
            'page_size': 15,
          });
          return {
            'products': [_backendProduct()],
          };
        });
        final repository = ProductRemoteRepositoryImpl(apiClient);

        final result = await repository.getProducts(
          citySlug: 'sharm-el-sheikh',
        );

        result.when(
          success: (products) => expect(products.single.id, '42'),
          failure: (failure) => fail(failure.message),
        );
      },
    );

    for (final entry in <String, Object?>{
      'a direct list': [_backendProduct()],
      'a results envelope': {
        'results': [_backendProduct()],
      },
      'an items envelope': {
        'items': [_backendProduct()],
      },
      'a products envelope': {
        'products': [_backendProduct()],
      },
    }.entries) {
      test('loads products from ${entry.key}', () async {
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'GET');
          expect(request.path, '/home/products/');
          return entry.value;
        });
        final repository = ProductRemoteRepositoryImpl(apiClient);

        final result = await repository.getProducts();

        result.when(
          success: (products) => expect(products.single.id, '42'),
          failure: (failure) => fail(failure.message),
        );
      });
    }

    test('searches products without forwarding the selected city', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/home/search/');
        expect(request.queryParameters, {'q': 'shoe'});
        return {
          'results': [_backendProduct()],
        };
      });
      final repository = ProductRemoteRepositoryImpl(apiClient);

      final result = await repository.searchProducts(
        ' shoe ',
        citySlug: 'sharm-el-sheikh',
      );

      result.when(
        success: (products) => expect(products.single.id, '42'),
        failure: (failure) => fail(failure.message),
      );
    });

    test('loads categories and brands from remote endpoints', () async {
      final apiClient = FakeApiClient((request) {
        if (request.path == '/home/classifications/') {
          expect(request.queryParameters, isNull);
          return {
            'market_classifications': [
              {
                'id': 7,
                'name': 'Supermarket',
                'classification_type': 'popular',
                'market_count': 5,
              },
              {
                'id': 8,
                'name': 'Restaurants',
                'classification_type': 'featured',
                'market_count': 3,
              },
              {
                'id': 9,
                'name': 'Pharmacies',
                'classification_type': 'normal',
                'market_count': 2,
              },
            ],
          };
        }
        fail('Unexpected request ${request.method} ${request.path}');
      });
      final repository = ProductRemoteRepositoryImpl(apiClient);

      final categoriesResult = await repository.getCategories();
      final brandsResult = await repository.getBrands();

      categoriesResult.when(
        success: (categories) {
          expect(categories.map((category) => category.name), [
            'Supermarket',
            'Restaurants',
            'Pharmacies',
          ]);
          expect(categories.first.marketCount, 5);
          expect(categories.first.classificationType, 'popular');
        },
        failure: (failure) => fail(failure.message),
      );
      brandsResult.when(
        success: (brands) => expect(brands.map((brand) => brand.name), [
          'Supermarket',
          'Restaurants',
          'Pharmacies',
        ]),
        failure: (failure) => fail(failure.message),
      );
    });

    test('coalesces simultaneous classification consumers', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.path, '/home/classifications/');
        return {
          'market_classifications': [
            {'id': 7, 'name': 'Supermarket'},
          ],
        };
      });
      final repository = ProductRemoteRepositoryImpl(apiClient);

      final categoriesFuture = repository.getCategories();
      final brandsFuture = repository.getBrands();
      final categoriesResult = await categoriesFuture;
      final brandsResult = await brandsFuture;

      categoriesResult.when(
        success: (categories) => expect(categories, hasLength(1)),
        failure: (failure) => fail(failure.message),
      );
      brandsResult.when(
        success: (brands) => expect(brands, hasLength(1)),
        failure: (failure) => fail(failure.message),
      );
      expect(
        apiClient.requests.where(
          (request) => request.path == '/home/classifications/',
        ),
        hasLength(1),
      );
    });

    test('maps backend product market and variant price range', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.path, '/home/products/');
        return {
          'products': [_backendProduct()],
        };
      });
      final repository = ProductRemoteRepositoryImpl(apiClient);

      final result = await repository.getProducts();

      result.when(
        success: (products) {
          final product = products.single;
          expect(product.id, '42');
          expect(product.title, 'Red Apple');
          expect(product.brand, 'Fresh Market');
          expect(product.price, '120.00 ~ 180.00');
          expect(product.code, isNull);
          expect(product.tags, isNot(contains('Fruit')));
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test(
      'maps a missing address response to the add address message',
      () async {
        final repository = ProductRemoteRepositoryImpl(
          FakeApiClient(
            (_) => throw _addressRequiredException('/home/products/'),
          ),
        );

        final result = await repository.getProducts();

        result.when(
          success: (_) => fail('Expected the request to fail.'),
          failure: (failure) => expect(failure.message, addressRequiredMessage),
        );
      },
    );

    test('returns a backend failure without demo fallback', () async {
      final apiClient = FakeApiClient(
        (_) => throw _serverException('/home/products/'),
      );
      final repository = ProductRemoteRepositoryImpl(apiClient);

      final result = await repository.getProducts();

      result.when(
        success: (_) => fail('Expected the backend failure to be surfaced.'),
        failure: (failure) {
          expect(failure.message, isNotEmpty);
          expect(apiClient.requests, hasLength(1));
        },
      );
    });
  });
}

DioException _addressRequiredException(String path) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: 400,
      data: {
        'detail': 'A user address is required before loading the home page.',
      },
    ),
    type: DioExceptionType.badResponse,
  );
}

DioException _serverException(String path) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: 500,
      data: {'detail': 'Catalog unavailable.'},
    ),
    type: DioExceptionType.badResponse,
  );
}

Map<String, Object?> _backendProduct() {
  return {
    'id': 42,
    'name': 'Red Apple',
    'description': 'Fresh fruit',
    'image': '',
    'discount': '10.00',
    'market': {'id': 9, 'name': 'Fresh Market'},
    'variants': [
      {'id': 1, 'price': '120.00', 'sku': 'SKU-1'},
      {'id': 2, 'price': '180.00', 'sku': 'SKU-2'},
    ],
  };
}
