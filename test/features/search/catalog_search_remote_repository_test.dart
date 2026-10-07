import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/cache/persistent_json_cache.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/search/data/repositories/catalog_search_remote_repository.dart';

import '../../helpers/fake_api_client.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Map<String, dynamic> payload() => {
    'results': [
      {
        'id': 42,
        'name': 'بيتزا',
        'market': {'id': 7, 'name': 'النور'},
      },
    ],
    'markets': [
      {'id': 7, 'name': 'النور', 'classification_id': 3, 'product_count': 12},
    ],
    'categories': [
      {'id': 3, 'name': 'مطاعم', 'market_count': 2},
    ],
    'next': '/api/v1/home/search/?page=2',
  };

  test(
    'maps products markets and categories and requests grouped search',
    () async {
      final api = FakeApiClient((request) {
        expect(request.path, '/home/search/');
        expect(request.queryParameters, {
          'q': 'مطاعم',
          'include': 'all',
          'page': 1,
        });
        return payload();
      });
      final result = await CatalogSearchRemoteRepository(
        api,
      ).search('مطاعم', citySlug: 'cairo');
      result.when(
        success: (results) {
          expect(results.products.single.id, '42');
          expect(results.markets.single.productCount, 12);
          expect(results.categories.single.marketCount, 2);
          expect(results.hasMoreProducts, isTrue);
        },
        failure: (failure) => fail(failure.message),
      );
    },
  );

  test('subsequent pages may omit markets and categories', () async {
    final api = FakeApiClient((_) => {'results': [], 'next': null});
    final result = await CatalogSearchRemoteRepository(
      api,
    ).search('مطاعم', citySlug: 'cairo', page: 2);
    expect(result, isA<ApiSuccess>());
  });

  test('empty result lists are successful', () async {
    final api = FakeApiClient(
      (_) => {'results': [], 'markets': [], 'categories': [], 'next': null},
    );
    final result = await CatalogSearchRemoteRepository(
      api,
    ).search('none', citySlug: 'cairo');
    expect(result, isA<ApiSuccess>());
  });

  test(
    'malformed payloads and old product-only responses fail explicitly',
    () async {
      for (final invalid in [
        {'results': [], 'next': null},
        {...payload(), 'markets': 'invalid'},
        {
          ...payload(),
          'categories': [null],
        },
        {
          ...payload(),
          'categories': [
            {'id': 3},
          ],
        },
      ]) {
        final result = await CatalogSearchRemoteRepository(
          FakeApiClient((_) => invalid),
        ).search('مطاعم', citySlug: 'cairo');
        expect(result, isA<ApiFailure>());
      }
    },
  );

  test('network and authentication errors map to typed failures', () async {
    for (final status in [null, 401]) {
      final request = RequestOptions(path: '/home/search/');
      final result = await CatalogSearchRemoteRepository(
        FakeApiClient(
          (_) => throw DioException(
            requestOptions: request,
            response: status == null
                ? null
                : Response(requestOptions: request, statusCode: status),
            type: status == null
                ? DioExceptionType.connectionError
                : DioExceptionType.badResponse,
          ),
        ),
      ).search('مطاعم', citySlug: 'cairo');
      expect(result, isA<ApiFailure>());
      if (status == 401) {
        expect((result as ApiFailure).failure, isA<UnauthorizedFailure>());
      }
    }
  });

  test('offline search preserves the existing city catalog fallback', () async {
    const cache = PersistentJsonCache();
    await cache.write('products.cairo', {'products': payload()['results']});
    await cache.write('store.v5.cairo', {
      'market_classifications': [
        {
          'id': 3,
          'name': 'مطاعم',
          'market_count': 1,
          'markets': [
            {
              'id': 7,
              'name': 'مطاعم النور',
              'status': 'active',
              'classification_id': 3,
            },
          ],
        },
      ],
    });
    final api = FakeApiClient(
      (_) => throw DioException(
        requestOptions: RequestOptions(path: '/home/search/'),
        type: DioExceptionType.connectionError,
      ),
    );
    final repository = CatalogSearchRemoteRepository(api, cache: cache);
    final result = await repository.search('مطاعم', citySlug: 'cairo');
    final cached = result as ApiSuccess;
    expect(cached.origin, DataOrigin.cache);
    expect(cached.data.categories, hasLength(1));
    expect(cached.data.markets, hasLength(1));
    final otherCity = await repository.search('مطاعم', citySlug: 'alexandria');
    expect(otherCity, isA<ApiFailure>());
    final product = await repository.search('بيتزا', citySlug: 'cairo');
    expect((product as ApiSuccess).data.products, hasLength(1));
  });

  test(
    'authentication failures never fall back to cached catalog data',
    () async {
      const cache = PersistentJsonCache();
      await cache.write('products.cairo', {'products': payload()['results']});
      final request = RequestOptions(path: '/home/search/');
      final api = FakeApiClient(
        (_) => throw DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: 401),
          type: DioExceptionType.badResponse,
        ),
      );
      final result = await CatalogSearchRemoteRepository(
        api,
        cache: cache,
      ).search('بيتزا', citySlug: 'cairo');
      expect(result, isA<ApiFailure>());
    },
  );
}
