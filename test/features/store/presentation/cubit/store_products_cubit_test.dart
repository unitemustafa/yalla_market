import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_product_page.dart';
import 'package:yalla_market/features/store/domain/repositories/store_products_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_products_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_products_cubit.dart';

void main() {
  group('StoreProductsCubit', () {
    late _StoreProductsRepository repository;
    late StoreProductsCubit cubit;

    setUp(() {
      repository = _StoreProductsRepository();
      cubit = StoreProductsCubit(GetStoreProductsUseCase(repository));
    });

    tearDown(() => cubit.close());

    test(
      'revalidates 300 loaded products in aligned batches and continues without gaps',
      () async {
        var now = DateTime.utc(2030);
        final repository = _BatchedRepository();
        repository.handler = (call) {
          final start = (call.page - 1) * call.pageSize;
          return ApiResult.success(
            _page(
              List.generate(
                call.pageSize,
                (i) => _product((start + i).toString()),
              ),
              count: 1000,
              hasMore: start + call.pageSize < 1000,
            ),
          );
        };
        final cubit = StoreProductsCubit(
          GetStoreProductsUseCase(repository),
          now: () => now,
        );
        addTearDown(cubit.close);
        await cubit.configure(marketId: 'market');
        for (var i = 0; i < 9; i++) {
          await cubit.loadMore();
        }
        expect(cubit.state.products.length, 300);
        repository.calls.clear();
        now = now.add(const Duration(minutes: 2));
        await cubit.refreshIfStale();
        expect(repository.calls.map((c) => c.pageSize), [90, 90, 90, 90]);
        expect(cubit.state.products.length, 360);
        await cubit.loadMore();
        expect(repository.calls.last.page, 13);
        expect(
          cubit.state.products.map((p) => p.id),
          List.generate(390, (i) => i.toString()),
        );
      },
    );

    test(
      'loads all 10000 products in bounded pages and stops at the end',
      () async {
        const count = 10000;
        repository.handler = (call) {
          final start = (call.page - 1) * call.pageSize;
          final end = (start + call.pageSize).clamp(0, count);
          return ApiResult.success(
            _page(
              [
                for (var index = start; index < end; index++)
                  _product('$index'),
              ],
              hasMore: end < count,
              count: count,
            ),
          );
        };

        await cubit.configure(marketId: 'market-1');
        expect(cubit.state.products, hasLength(30));
        for (var page = 2; page <= 334; page++) {
          await cubit.loadMore();
          expect(cubit.state.products.length, (page * 30).clamp(0, count));
          expect(cubit.state.error, isNull);
          expect(cubit.state.moreError, isNull);
        }
        expect(cubit.state.products.map((product) => product.id), [
          for (var index = 0; index < count; index++) '$index',
        ]);
        expect(cubit.state.hasMore, isFalse);
        expect(repository.calls.every((call) => call.pageSize == 30), isTrue);
        await cubit.loadMore();
        expect(repository.calls, hasLength(334));
      },
    );

    test(
      'configuring loads the first page with the selected filters',
      () async {
        repository.handler = (call) =>
            ApiResult.success(_page([_product('one')], count: 1));

        await cubit.configure(
          marketId: ' market-1 ',
          query: ' apples ',
          subcategoryId: ' fruit ',
          sort: StoreProductSort.newest,
          scopeKey: 'cairo:user-1',
        );

        expect(repository.calls, hasLength(1));
        expect(
          repository.calls.single,
          _StoreProductsCall(
            marketId: 'market-1',
            page: 1,
            pageSize: 30,
            query: 'apples',
            subcategoryId: 'fruit',
            sort: StoreProductSort.newest,
          ),
        );
        expect(cubit.state.products.map((product) => product.id), ['one']);
        expect(cubit.state.visibleProducts, cubit.state.products);
        expect(cubit.state.isLoading, isFalse);
      },
    );

    test(
      'loading more appends new products and replaces duplicate data in place',
      () async {
        repository.handler = (call) => ApiResult.success(
          call.page == 1
              ? _page(
                  [_product('one'), _product('two', title: 'Old')],
                  hasMore: true,
                  count: 3,
                )
              : _page([
                  _product('two', title: 'New'),
                  _product('three'),
                ], count: 3),
        );

        await cubit.configure(marketId: 'market-1');
        await cubit.loadMore();

        expect(repository.calls.map((call) => call.page), [1, 2]);
        expect(cubit.state.products.map((product) => product.id), [
          'one',
          'two',
          'three',
        ]);
        expect(cubit.state.products[1].title, 'New');
        expect(cubit.state.hasMore, isFalse);
        expect(cubit.state.count, 3);
      },
    );

    test(
      'overlapping load more requests issue one request for the next page',
      () async {
        final secondPage = Completer<ApiResult<StoreProductPage>>();
        repository.handler = (call) => call.page == 1
            ? ApiResult.success(
                _page([_product('one')], hasMore: true, count: 2),
              )
            : secondPage.future;

        await cubit.configure(marketId: 'market-1');
        final first = cubit.loadMore();
        final overlapping = cubit.loadMore();
        await Future<void>.delayed(Duration.zero);

        expect(repository.calls.map((call) => call.page), [1, 2]);
        expect(cubit.state.loadingMore, isTrue);
        secondPage.complete(
          ApiResult.success(_page([_product('two')], count: 2)),
        );
        await Future.wait([first, overlapping]);

        expect(cubit.state.products.map((product) => product.id), [
          'one',
          'two',
        ]);
        expect(cubit.state.loadingMore, isFalse);
      },
    );

    test(
      'a failed additional page preserves products and retry requests that page',
      () async {
        var secondPageAttempts = 0;
        repository.handler = (call) {
          if (call.page == 1) {
            return ApiResult.success(
              _page([_product('one')], hasMore: true, count: 2),
            );
          }
          secondPageAttempts++;
          return secondPageAttempts == 1
              ? const ApiResult.failure(ServerFailure('offline'))
              : ApiResult.success(_page([_product('two')], count: 2));
        };

        await cubit.configure(marketId: 'market-1');
        await cubit.loadMore();

        expect(cubit.state.products.map((product) => product.id), ['one']);
        expect(cubit.state.moreError, 'offline');
        expect(cubit.state.error, isNull);
        await cubit.retry();

        expect(repository.calls.map((call) => call.page), [1, 2, 2]);
        expect(cubit.state.products.map((product) => product.id), [
          'one',
          'two',
        ]);
        expect(cubit.state.moreError, isNull);
      },
    );

    test('a newer scope discards an older delayed response', () async {
      final oldResponse = Completer<ApiResult<StoreProductPage>>();
      repository.handler = (call) => call.query == 'old'
          ? oldResponse.future
          : ApiResult.success(_page([_product('new')], count: 1));

      final old = cubit.configure(
        marketId: 'market-1',
        query: 'old',
        scopeKey: 'user-1',
      );
      await Future<void>.delayed(Duration.zero);
      await cubit.configure(
        marketId: 'market-1',
        query: 'new',
        scopeKey: 'user-2',
      );
      oldResponse.complete(
        ApiResult.success(_page([_product('old')], count: 1)),
      );
      await old;

      expect(cubit.state.products.map((product) => product.id), ['new']);
      expect(cubit.state.error, isNull);
    });

    test('closing ignores a late response without emitting an error', () async {
      final response = Completer<ApiResult<StoreProductPage>>();
      repository.handler = (_) => response.future;

      final pending = cubit.configure(marketId: 'market-1');
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      response.complete(ApiResult.success(_page([_product('late')], count: 1)));
      await pending;

      expect(cubit.isClosed, isTrue);
    });

    test('fresh results skip lifecycle reloads', () async {
      var now = DateTime.utc(2026, 10, 13, 10);
      final lifecycleCubit = StoreProductsCubit(
        GetStoreProductsUseCase(repository),
        now: () => now,
      );
      addTearDown(lifecycleCubit.close);
      repository.handler = (_) =>
          ApiResult.success(_page([_product('one')], count: 1));

      await lifecycleCubit.configure(marketId: 'market-1');
      now = now.add(const Duration(seconds: 59));
      await lifecycleCubit.refreshIfStale();

      expect(repository.calls.map((call) => call.page), [1]);
    });

    test(
      'a stale lifecycle refresh atomically reloads every loaded page',
      () async {
        var now = DateTime.utc(2026, 10, 13, 10);
        final lifecycleCubit = StoreProductsCubit(
          GetStoreProductsUseCase(repository),
          now: () => now,
        );
        addTearDown(lifecycleCubit.close);
        var refresh = false;
        repository.handler = (call) => ApiResult.success(
          call.page == 1
              ? _page(
                  [_product(refresh ? 'one-new' : 'one')],
                  hasMore: true,
                  count: 2,
                )
              : _page([_product(refresh ? 'two-new' : 'two')], count: 2),
        );

        await lifecycleCubit.configure(marketId: 'market-1');
        await lifecycleCubit.loadMore();
        refresh = true;
        now = now.add(const Duration(seconds: 60));
        await lifecycleCubit.refreshIfStale();

        expect(repository.calls.map((call) => call.page), [1, 2, 1, 2]);
        expect(lifecycleCubit.state.products.map((product) => product.id), [
          'one-new',
          'two-new',
        ]);
      },
    );

    test(
      'a scope change clears old cards while the next first page is pending',
      () async {
        final next = Completer<ApiResult<StoreProductPage>>();
        var calls = 0;
        repository.handler = (_) => ++calls == 2
            ? next.future
            : ApiResult.success(_page([_product('old')], count: 1));

        await cubit.configure(marketId: 'market-1', scopeKey: 'user-1');
        final pending = cubit.configure(
          marketId: 'market-1',
          scopeKey: 'user-2',
        );
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.products, isEmpty);
        next.complete(ApiResult.success(_page([_product('new')], count: 1)));
        await pending;

        expect(cubit.state.products.map((product) => product.id), ['new']);
      },
    );

    test(
      'an invalidation during fetch schedules one follow-up refresh',
      () async {
        var now = DateTime.utc(2026, 10, 13, 10);
        final lifecycleCubit = StoreProductsCubit(
          GetStoreProductsUseCase(repository),
          now: () => now,
        );
        addTearDown(lifecycleCubit.close);
        final delayed = Completer<ApiResult<StoreProductPage>>();
        var requests = 0;
        repository.handler = (_) {
          requests++;
          return requests == 2
              ? delayed.future
              : ApiResult.success(_page([_product('p$requests')], count: 1));
        };

        await lifecycleCubit.configure(marketId: 'market-1');
        now = now.add(const Duration(seconds: 60));
        final firstRefresh = lifecycleCubit.refreshIfStale(invalidated: true);
        await Future<void>.delayed(Duration.zero);
        await lifecycleCubit.refreshIfStale(invalidated: true);
        delayed.complete(ApiResult.success(_page([_product('p2')], count: 1)));
        await firstRefresh;
        await Future<void>.delayed(Duration.zero);

        expect(requests, 3);
        expect(lifecycleCubit.state.products.single.id, 'p3');
      },
    );

    test(
      'a lifecycle refresh failure keeps pages and retry reloads them',
      () async {
        var now = DateTime.utc(2026, 10, 13, 10);
        final lifecycleCubit = StoreProductsCubit(
          GetStoreProductsUseCase(repository),
          now: () => now,
        );
        addTearDown(lifecycleCubit.close);
        var refreshAttempt = false;
        repository.handler = (call) {
          if (refreshAttempt && call.page == 1) {
            refreshAttempt = false;
            return const ApiResult.failure(ServerFailure('offline'));
          }
          return ApiResult.success(
            call.page == 1
                ? _page([_product('one')], hasMore: true, count: 2)
                : _page([_product('two')], count: 2),
          );
        };

        await lifecycleCubit.configure(marketId: 'market-1');
        await lifecycleCubit.loadMore();
        refreshAttempt = true;
        now = now.add(const Duration(seconds: 60));
        await lifecycleCubit.refreshIfStale();
        expect(lifecycleCubit.state.products.map((product) => product.id), [
          'one',
          'two',
        ]);
        expect(lifecycleCubit.state.error, 'offline');
        await lifecycleCubit.retry();

        expect(repository.calls.map((call) => call.page), [1, 2, 1, 1, 2]);
        expect(lifecycleCubit.state.error, isNull);
        expect(lifecycleCubit.state.products.map((product) => product.id), [
          'one',
          'two',
        ]);
      },
    );
  });
}

StoreProductPage _page(
  List<ProductData> products, {
  bool hasMore = false,
  int? count,
}) => StoreProductPage(
  products: products,
  count: count ?? products.length,
  hasMore: hasMore,
);

ProductData _product(String id, {String? title}) => ProductData(
  id: id,
  image: '',
  title: title ?? id,
  brand: 'Store',
  price: '10',
  oldPrice: null,
  discount: '',
  tags: const [],
);

class _StoreProductsRepository implements StoreProductsRepository {
  final List<_StoreProductsCall> calls = [];
  FutureOr<ApiResult<StoreProductPage>> Function(_StoreProductsCall call)?
  handler;

  @override
  Future<ApiResult<StoreProductPage>> getProducts(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  }) async {
    final call = _StoreProductsCall(
      marketId: marketId,
      page: page,
      pageSize: pageSize,
      query: query,
      subcategoryId: subcategoryId,
      sort: sort,
    );
    calls.add(call);
    return await handler?.call(call) ??
        const ApiResult.success(
          StoreProductPage(products: [], count: 0, hasMore: false),
        );
  }
}

class _StoreProductsCall {
  const _StoreProductsCall({
    required this.marketId,
    required this.page,
    required this.pageSize,
    required this.query,
    required this.subcategoryId,
    required this.sort,
  });

  final String marketId;
  final int page;
  final int pageSize;
  final String query;
  final String? subcategoryId;
  final StoreProductSort sort;

  @override
  bool operator ==(Object other) =>
      other is _StoreProductsCall &&
      marketId == other.marketId &&
      page == other.page &&
      pageSize == other.pageSize &&
      query == other.query &&
      subcategoryId == other.subcategoryId &&
      sort == other.sort;

  @override
  int get hashCode =>
      Object.hash(marketId, page, pageSize, query, subcategoryId, sort);
}

class _BatchedRepository extends _StoreProductsRepository
    implements BatchedStoreProductsRepository {}
