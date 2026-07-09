import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/address_required_error.dart';
import 'package:yalla_market/features/store/data/repositories/product_remote_repository_impl.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('ProductRemoteRepositoryImpl', () {
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

    test('loads products without forwarding the selected city', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/home/products/');
        expect(request.queryParameters, isNull);
        return {
          'products': [_backendProduct()],
        };
      });
      final repository = ProductRemoteRepositoryImpl(apiClient);

      final result = await repository.getProducts(citySlug: 'sharm-el-sheikh');

      result.when(
        success: (products) => expect(products.single.id, '42'),
        failure: (failure) => fail(failure.message),
      );
    });

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
            'common_categories': [
              {'id': 7, 'name': 'Supermarket', 'product_count': 5},
            ],
          };
        }
        fail('Unexpected request ${request.method} ${request.path}');
      });
      final repository = ProductRemoteRepositoryImpl(apiClient);

      final categoriesResult = await repository.getCategories();
      final brandsResult = await repository.getBrands();

      categoriesResult.when(
        success: (categories) => expect(categories.single.name, 'Supermarket'),
        failure: (failure) => fail(failure.message),
      );
      brandsResult.when(
        success: (brands) => expect(brands.single.name, 'Supermarket'),
        failure: (failure) => fail(failure.message),
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
