import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/location/domain/usecases/location_usecases.dart';
import 'package:yalla_market/features/search/domain/entities/catalog_search_results.dart';
import 'package:yalla_market/features/search/domain/usecases/search_catalog_usecase.dart';
import 'package:yalla_market/features/search/presentation/cubit/catalog_search_cubit.dart';
import 'package:yalla_market/features/search/presentation/cubit/catalog_search_state.dart';

import 'search_fixtures.dart';

void main() {
  late TestCatalogSearchRepository repository;
  late SearchLocationRepository location;
  late CatalogSearchCubit cubit;
  setUp(() {
    repository = TestCatalogSearchRepository();
    location = SearchLocationRepository();
    cubit = CatalogSearchCubit(
      SearchCatalogUseCase(repository),
      GetSelectedCityUseCase(location),
    );
    addTearDown(cubit.close);
  });

  test('use case trims queries and skips empty requests', () async {
    final useCase = SearchCatalogUseCase(repository);
    await useCase('  ', citySlug: 'cairo');
    expect(repository.calls, isEmpty);
    await useCase(' مطاعم ', citySlug: 'cairo');
    expect(repository.calls.single.query, 'مطاعم');
  });

  test(
    'search returns three types with selected city and reloads categories for every query',
    () async {
      repository.handler = (query, _) => ApiResult.success(
        query == 'بيتزا'
            ? const CatalogSearchResults(products: [searchProduct])
            : searchResults,
      );
      await cubit.search('بيتزا');
      expect(cubit.state.results.categories, isEmpty);
      await cubit.search(' مطاعم ');
      expect(cubit.state, isA<CatalogSearchReady>());
      expect(cubit.state.query, 'مطاعم');
      expect(cubit.state.results.categories.single.id, searchCategory.id);
      expect(cubit.state.results.markets.single.id, searchMarket.id);
      expect(cubit.state.results.products.single.id, searchProduct.id);
      expect(repository.calls.last.city, 'cairo');
    },
  );

  test('old completions cannot replace a newer query', () async {
    final old = Completer<ApiResult<CatalogSearchResults>>();
    repository.handler = (query, _) =>
        query == 'old' ? old.future : const ApiResult.success(searchResults);
    final pending = cubit.search('old');
    await Future<void>.delayed(Duration.zero);
    await cubit.search('مطاعم');
    old.complete(const ApiResult.success(CatalogSearchResults()));
    await pending;
    expect(cubit.state.query, 'مطاعم');
    expect(cubit.state.results.categories, isNotEmpty);
  });

  test('clearing cancels pending search results', () async {
    final pendingResult = Completer<ApiResult<CatalogSearchResults>>();
    repository.handler = (_, _) => pendingResult.future;
    final pending = cubit.search('مطاعم');
    await Future<void>.delayed(Duration.zero);
    await cubit.search('');
    pendingResult.complete(const ApiResult.success(searchResults));
    await pending;
    expect(cubit.state, isA<CatalogSearchInitial>());
  });

  test('missing city and city lookup errors are explicit', () async {
    location.result = const ApiResult.success(null);
    await cubit.search('مطاعم');
    expect(cubit.state, isA<CatalogSearchNeedsCity>());
    expect(repository.calls, isEmpty);
    location.result = const ApiResult.failure(
      ServerFailure('City unavailable'),
    );
    await cubit.search('مطاعم');
    expect((cubit.state as CatalogSearchFailure).message, 'City unavailable');
  });

  test('search failure can be retried', () async {
    repository.handler = (_, _) =>
        const ApiResult.failure(ServerFailure('offline'));
    await cubit.search('مطاعم');
    expect(cubit.state, isA<CatalogSearchFailure>());
    repository.handler = null;
    await cubit.search('مطاعم');
    expect(cubit.state, isA<CatalogSearchReady>());
  });

  test(
    'pagination preserves markets and categories and deduplicates products',
    () async {
      repository.handler = (_, page) => ApiResult.success(
        page == 1
            ? const CatalogSearchResults(
                products: [searchProduct],
                markets: [searchMarket],
                categories: [searchCategory],
                hasMoreProducts: true,
              )
            : const CatalogSearchResults(products: [searchProduct]),
      );
      await cubit.search('مطاعم');
      await cubit.loadMore();
      expect(repository.calls.last.page, 2);
      expect(cubit.state.results.products, hasLength(1));
      expect(cubit.state.results.markets, hasLength(1));
      expect(cubit.state.results.categories, hasLength(1));
      expect(cubit.state.results.hasMoreProducts, isFalse);
    },
  );

  test(
    'pagination failures preserve results and retry the same page',
    () async {
      repository.handler = (_, page) => page == 1
          ? const ApiResult.success(
              CatalogSearchResults(
                products: [searchProduct],
                categories: [searchCategory],
                hasMoreProducts: true,
              ),
            )
          : const ApiResult.failure(ServerFailure('offline'));
      await cubit.search('مطاعم');
      await cubit.loadMore();
      expect((cubit.state as CatalogSearchReady).moreError, 'offline');
      expect(cubit.state.results.categories, hasLength(1));
      await cubit.loadMore();
      expect(repository.calls.map((call) => call.page), [1, 2, 2]);
    },
  );

  test('old pagination cannot merge into a new search', () async {
    final next = Completer<ApiResult<CatalogSearchResults>>();
    repository.handler = (_, page) => page == 2
        ? next.future
        : const ApiResult.success(
            CatalogSearchResults(
              categories: [searchCategory],
              hasMoreProducts: true,
            ),
          );
    await cubit.search('old');
    final pending = cubit.loadMore();
    await cubit.search('new');
    next.complete(const ApiResult.success(searchResults));
    await pending;
    expect(cubit.state.query, 'new');
    expect(cubit.state.results.products, isEmpty);
  });
}
