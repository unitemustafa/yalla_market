import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/usecases/prepare_product_results_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/product_results_cubit.dart';

void main() {
  group('ProductResultsCubit', () {
    test(
      'does not recompute for pagination, identical inputs, or page-size changes',
      () async {
        final prepare = _CountingPrepareProductResultsUseCase();
        final cubit = ProductResultsCubit(prepare);
        addTearDown(cubit.close);
        final products = List.generate(25, (index) => _product('$index'));

        await cubit.update(
          products: products,
          query: '',
          sortOption: 'Newest',
          pageSize: 10,
        );
        cubit.selectPage(1);
        await cubit.update(
          products: products,
          query: '   ',
          sortOption: 'Newest',
          pageSize: 5,
        );

        expect(prepare.callCount, 1);
        final state = cubit.state as ProductResultsReady;
        expect(state.page, 1);
        expect(state.pageSize, 5);
      },
    );

    test(
      'clamps the selected page after results or page size shrink',
      () async {
        final cubit = ProductResultsCubit(
          _CountingPrepareProductResultsUseCase(),
        );
        addTearDown(cubit.close);
        final products = List.generate(25, (index) => _product('$index'));
        await cubit.update(
          products: products,
          query: '',
          sortOption: 'Newest',
          pageSize: 10,
        );
        cubit.selectPage(2);
        await cubit.update(
          products: products,
          query: '',
          sortOption: 'Newest',
          pageSize: 20,
        );
        expect((cubit.state as ProductResultsReady).page, 1);

        await cubit.update(
          products: [_product('only')],
          query: '',
          sortOption: 'Newest',
          pageSize: 20,
        );
        expect((cubit.state as ProductResultsReady).page, 0);
      },
    );

    test(
      'recalculates when source, category, or preference inputs change',
      () async {
        final prepare = _CountingPrepareProductResultsUseCase();
        final cubit = ProductResultsCubit(prepare);
        addTearDown(cubit.close);
        final products = [_product('one')];

        Future<void> update({Object? categoryKey, List<ProductData>? source}) =>
            cubit.update(
              products: source ?? products,
              query: '',
              sortOption: 'Newest',
              pageSize: 10,
              categoryKey: categoryKey,
            );

        await update(categoryKey: 'first');
        await update(categoryKey: 'second');
        await update(categoryKey: 'second', source: [_product('two')]);

        expect(prepare.callCount, 3);
      },
    );

    test('resets pagination after a query or sort change', () async {
      final cubit = ProductResultsCubit(
        _CountingPrepareProductResultsUseCase(),
      );
      addTearDown(cubit.close);
      final products = List.generate(25, (index) => _product('$index'));
      await cubit.update(
        products: products,
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );
      cubit.selectPage(2);
      await cubit.update(
        products: products,
        query: 'product',
        sortOption: 'Newest',
        pageSize: 10,
      );
      expect((cubit.state as ProductResultsReady).page, 0);
    });

    test('emits a failure when initial result preparation fails', () async {
      final cubit = ProductResultsCubit(
        _CountingPrepareProductResultsUseCase(
          result: const ApiResult.failure(
            ServerFailure('Could not prepare products.'),
          ),
        ),
      );
      addTearDown(cubit.close);

      await cubit.update(
        products: [_product('one')],
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );

      expect(cubit.state, isA<ProductResultsFailure>());
      expect(
        (cubit.state as ProductResultsFailure).message,
        'Could not prepare products.',
      );
    });

    test('keeps prior content while preparation is pending', () async {
      final prepare = _ControlledPrepareProductResultsUseCase();
      final cubit = ProductResultsCubit(prepare);
      addTearDown(cubit.close);
      final initial = cubit.update(
        products: [_product('old')],
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );
      prepare.succeed(0, [_product('old')]);
      await initial;

      final update = cubit.update(
        products: [_product('new')],
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );

      final pending = cubit.state as ProductResultsReady;
      expect(pending.isPreparing, isTrue);
      expect(pending.products.map((product) => product.id), ['old']);

      prepare.succeed(1, [_product('new')]);
      await update;
      expect(
        (cubit.state as ProductResultsReady).products.map(
          (product) => product.id,
        ),
        ['new'],
      );
    });

    test('keeps only the latest overlapping result', () async {
      final prepare = _ControlledPrepareProductResultsUseCase();
      final cubit = ProductResultsCubit(prepare);
      addTearDown(cubit.close);

      final oldUpdate = cubit.update(
        products: [_product('old')],
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );
      final newUpdate = cubit.update(
        products: [_product('new')],
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );

      prepare.succeed(1, [_product('new')]);
      await newUpdate;
      prepare.succeed(0, [_product('old')]);
      await oldUpdate;

      expect(
        (cubit.state as ProductResultsReady).products.map(
          (product) => product.id,
        ),
        ['new'],
      );
    });

    test('keeps a page selected while same-query work is pending', () async {
      final prepare = _ControlledPrepareProductResultsUseCase();
      final cubit = ProductResultsCubit(prepare);
      addTearDown(cubit.close);
      final initialProducts = List.generate(
        25,
        (index) => _product('old-$index'),
      );
      final initial = cubit.update(
        products: initialProducts,
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );
      prepare.succeed(0, initialProducts);
      await initial;
      cubit.selectPage(2);

      final refreshedProducts = List.generate(
        25,
        (index) => _product('new-$index'),
      );
      final refresh = cubit.update(
        products: refreshedProducts,
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );
      cubit.selectPage(1);
      prepare.succeed(1, refreshedProducts);
      await refresh;

      expect((cubit.state as ProductResultsReady).page, 1);
    });

    test('retries an identical failed request', () async {
      final prepare = _ControlledPrepareProductResultsUseCase();
      final cubit = ProductResultsCubit(prepare);
      addTearDown(cubit.close);
      final products = [_product('one')];

      final failed = cubit.update(
        products: products,
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );
      prepare.fail(0, 'Preparation failed.');
      await failed;
      expect(cubit.state, isA<ProductResultsFailure>());

      final retry = cubit.update(
        products: products,
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );
      expect(prepare.callCount, 2);
      prepare.succeed(1, products);
      await retry;

      expect(
        (cubit.state as ProductResultsReady).products.map(
          (product) => product.id,
        ),
        ['one'],
      );
    });

    test('ignores a completed job after the cubit is closed', () async {
      final prepare = _ControlledPrepareProductResultsUseCase();
      final cubit = ProductResultsCubit(prepare);
      final updates = <ProductResultsState>[];
      final subscription = cubit.stream.listen(updates.add);
      addTearDown(subscription.cancel);

      final update = cubit.update(
        products: [_product('one')],
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
      );
      await cubit.close();
      prepare.succeed(0, [_product('one')]);
      await update;

      expect(cubit.isClosed, isTrue);
      expect(updates.whereType<ProductResultsFailure>(), isEmpty);
    });
  });
}

class _CountingPrepareProductResultsUseCase
    extends PrepareProductResultsUseCase {
  _CountingPrepareProductResultsUseCase({this.result});

  int callCount = 0;
  final ApiResult<List<ProductData>>? result;

  @override
  Future<ApiResult<List<ProductData>>> call(
    List<ProductData> products, {
    required String query,
    required String sortOption,
    String? subcategoryId,
  }) async {
    callCount += 1;
    return result ?? ApiResult.success(List.unmodifiable(products));
  }
}

class _ControlledPrepareProductResultsUseCase
    extends PrepareProductResultsUseCase {
  final _pending = <Completer<ApiResult<List<ProductData>>>>[];

  int get callCount => _pending.length;

  @override
  Future<ApiResult<List<ProductData>>> call(
    List<ProductData> products, {
    required String query,
    required String sortOption,
    String? subcategoryId,
  }) {
    final completer = Completer<ApiResult<List<ProductData>>>();
    _pending.add(completer);
    return completer.future;
  }

  void succeed(int index, List<ProductData> products) {
    _pending[index].complete(ApiResult.success(List.unmodifiable(products)));
  }

  void fail(int index, String message) {
    _pending[index].complete(ApiResult.failure(ServerFailure(message)));
  }
}

ProductData _product(String id) => ProductData(
  id: id,
  image: '',
  title: 'Product $id',
  brand: 'Market',
  price: '1',
  oldPrice: null,
  discount: '',
  tags: const [],
);
