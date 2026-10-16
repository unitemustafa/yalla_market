import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/usecases/prepare_product_results_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/product_results_cubit.dart';

void main() {
  group('ProductResultsCubit category cache', () {
    test(
      'revisiting a successful category does not start another preparation',
      () async {
        final prepare = _ControlledPrepare();
        final cubit = ProductResultsCubit(prepare);
        addTearDown(cubit.close);
        final products = [_product('one')];

        await _succeed(
          cubit,
          prepare,
          products,
          category: 'a',
          result: [_product('a')],
        );
        await _succeed(
          cubit,
          prepare,
          products,
          category: 'b',
          result: [_product('b')],
        );
        await cubit.update(
          products: products,
          query: '',
          sortOption: 'Newest',
          pageSize: 10,
          subcategoryId: 'a',
          categoryKey: 'a',
        );

        expect(prepare.calls, 2);
        final state = cubit.state as ProductResultsReady;
        expect(state.isPreparing, isFalse);
        expect(state.products.single.id, 'a');
      },
    );

    test(
      'evicts the least recently used category after three successful categories',
      () async {
        final prepare = _ControlledPrepare();
        final cubit = ProductResultsCubit(prepare);
        addTearDown(cubit.close);
        final products = [_product('one')];

        await _succeed(
          cubit,
          prepare,
          products,
          category: 'a',
          result: [_product('a')],
        );
        await _succeed(
          cubit,
          prepare,
          products,
          category: 'b',
          result: [_product('b')],
        );
        await cubit.update(
          products: products,
          query: '',
          sortOption: 'Newest',
          pageSize: 10,
          subcategoryId: 'a',
          categoryKey: 'a',
        );
        await _succeed(
          cubit,
          prepare,
          products,
          category: 'c',
          result: [_product('c')],
        );
        final revisitB = cubit.update(
          products: products,
          query: '',
          sortOption: 'Newest',
          pageSize: 10,
          subcategoryId: 'b',
          categoryKey: 'b',
        );

        expect(prepare.calls, 4);
        prepare.succeed(3, [_product('b2')]);
        await revisitB;
        expect((cubit.state as ProductResultsReady).products.single.id, 'b2');
      },
    );

    test(
      'a new source snapshot invalidates cached results even when product IDs match',
      () async {
        final prepare = _ControlledPrepare();
        final cubit = ProductResultsCubit(prepare);
        addTearDown(cubit.close);
        final first = [_product('same', title: 'Old')];
        final second = [_product('same', title: 'Updated')];

        await _succeed(cubit, prepare, first, category: 'a', result: first);
        final update = cubit.update(
          products: second,
          query: '',
          sortOption: 'Newest',
          pageSize: 10,
          subcategoryId: 'a',
          categoryKey: 'a',
        );

        expect(prepare.calls, 2);
        prepare.succeed(1, second);
        await update;
        expect(
          (cubit.state as ProductResultsReady).products.single.title,
          'Updated',
        );
      },
    );

    test('query and sort each invalidate category results', () async {
      final prepare = _ControlledPrepare();
      final cubit = ProductResultsCubit(prepare);
      addTearDown(cubit.close);
      final products = [_product('one')];
      await _succeed(cubit, prepare, products, category: 'a', result: products);
      for (final input in [
        (query: 'one', sort: 'Newest'),
        (query: 'one', sort: 'Name'),
      ]) {
        final update = cubit.update(
          products: products,
          query: input.query,
          sortOption: input.sort,
          pageSize: 10,
          subcategoryId: 'a',
          categoryKey: 'a',
        );
        prepare.succeed(prepare.calls - 1, products);
        await update;
      }
      expect(prepare.calls, 3);
    });

    test('a cache hit wins over an older pending preparation', () async {
      final prepare = _ControlledPrepare();
      final cubit = ProductResultsCubit(prepare);
      addTearDown(cubit.close);
      final products = [_product('one')];
      await _succeed(
        cubit,
        prepare,
        products,
        category: 'a',
        result: [_product('a')],
      );
      await _succeed(
        cubit,
        prepare,
        products,
        category: 'b',
        result: [_product('b')],
      );
      final pendingC = cubit.update(
        products: products,
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
        subcategoryId: 'c',
        categoryKey: 'c',
      );
      await cubit.update(
        products: products,
        query: '',
        sortOption: 'Newest',
        pageSize: 10,
        subcategoryId: 'a',
        categoryKey: 'a',
      );
      prepare.succeed(2, [_product('c')]);
      await pendingC;

      expect((cubit.state as ProductResultsReady).products.single.id, 'a');
    });

    test(
      'failed preparations are not cached and identical retry prepares again',
      () async {
        final prepare = _ControlledPrepare();
        final cubit = ProductResultsCubit(prepare);
        addTearDown(cubit.close);
        final products = [_product('one')];
        final failed = cubit.update(
          products: products,
          query: '',
          sortOption: 'Newest',
          pageSize: 10,
          subcategoryId: 'a',
          categoryKey: 'a',
        );
        prepare.fail(0);
        await failed;
        final retry = cubit.update(
          products: products,
          query: '',
          sortOption: 'Newest',
          pageSize: 10,
          subcategoryId: 'a',
          categoryKey: 'a',
        );

        expect(prepare.calls, 2);
        prepare.succeed(1, products);
        await retry;
      },
    );

    test(
      'cached results retain page semantics and close ignores late completion',
      () async {
        final prepare = _ControlledPrepare();
        final cubit = ProductResultsCubit(prepare);
        final products = List.generate(25, (i) => _product('$i'));
        await _succeed(
          cubit,
          prepare,
          products,
          category: 'a',
          result: products,
          pageSize: 10,
        );
        cubit.selectPage(2);
        await _succeed(
          cubit,
          prepare,
          products,
          category: 'b',
          result: products,
          pageSize: 10,
        );
        await cubit.update(
          products: products,
          query: '',
          sortOption: 'Newest',
          pageSize: 20,
          subcategoryId: 'a',
          categoryKey: 'a',
        );
        expect((cubit.state as ProductResultsReady).page, 1);

        final late = cubit.update(
          products: products,
          query: '',
          sortOption: 'Newest',
          pageSize: 20,
          subcategoryId: 'c',
          categoryKey: 'c',
        );
        await cubit.close();
        prepare.succeed(2, products);
        await late;
        expect(cubit.isClosed, isTrue);
      },
    );
  });
}

Future<void> _succeed(
  ProductResultsCubit cubit,
  _ControlledPrepare prepare,
  List<ProductData> products, {
  required String category,
  required List<ProductData> result,
  int pageSize = 10,
}) async {
  final update = cubit.update(
    products: products,
    query: '',
    sortOption: 'Newest',
    pageSize: pageSize,
    subcategoryId: category,
    categoryKey: category,
  );
  prepare.succeed(prepare.calls - 1, result);
  await update;
}

class _ControlledPrepare extends PrepareProductResultsUseCase {
  final pending = <Completer<ApiResult<List<ProductData>>>>[];
  int get calls => pending.length;
  @override
  Future<ApiResult<List<ProductData>>> call(
    List<ProductData> products, {
    required String query,
    required String sortOption,
    String? subcategoryId,
  }) {
    final completer = Completer<ApiResult<List<ProductData>>>();
    pending.add(completer);
    return completer.future;
  }

  void succeed(int index, List<ProductData> products) =>
      pending[index].complete(ApiResult.success(List.unmodifiable(products)));
  void fail(int index) =>
      pending[index].complete(const ApiResult.failure(ServerFailure('failed')));
}

ProductData _product(String id, {String? title}) => ProductData(
  id: id,
  image: '',
  title: title ?? id,
  brand: 'Market',
  price: '1',
  oldPrice: null,
  discount: '',
  tags: const [],
);
