import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/domain/computation_executor.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/usecases/prepare_product_results_usecase.dart';

void main() {
  const useCase = PrepareProductResultsUseCase();

  test(
    'filters query and both legacy and multi-subcategory assignments',
    () async {
      final products = [
        _product('legacy', title: 'Iced tea', subcategoryId: 'drinks'),
        _product(
          'many',
          title: 'Tea sampler',
          subcategories: const [
            StoreSubcategoryData(id: 'drinks', nameAr: '', nameEn: ''),
          ],
        ),
        _product('other', title: 'Coffee', subcategoryId: 'hot'),
      ];

      final result = await useCase(
        products,
        query: 'tea',
        sortOption: 'Newest',
        subcategoryId: ' drinks ',
      );

      expect(_data(result).map((product) => product.id), ['legacy', 'many']);
    },
  );

  test(
    'sorts price and name while newest preserves the incoming order',
    () async {
      final products = [
        _product('newest', title: 'Zebra', price: '30'),
        _product('middle', title: 'Apple', price: '20'),
        _product('oldest', title: 'Mango', price: '10'),
      ];

      expect(
        _data(
          await useCase(products, query: '', sortOption: 'Higher Price'),
        ).map((product) => product.id),
        ['newest', 'middle', 'oldest'],
      );
      expect(
        _data(
          await useCase(products, query: '', sortOption: 'Lower Price'),
        ).map((product) => product.id),
        ['oldest', 'middle', 'newest'],
      );
      expect(
        _data(
          await useCase(products, query: '', sortOption: 'Name'),
        ).map((product) => product.id),
        ['middle', 'oldest', 'newest'],
      );
      expect(
        _data(
          await useCase(products, query: '', sortOption: 'Newest'),
        ).map((product) => product.id),
        ['newest', 'middle', 'oldest'],
      );
    },
  );

  test(
    'does not mutate the source list and returns an unmodifiable result',
    () async {
      final products = [
        _product('one', title: 'Zebra', price: '1'),
        _product('two', title: 'Apple', price: '2'),
      ];

      final result = _data(
        await useCase(products, query: '', sortOption: 'Name'),
      );

      expect(products.map((product) => product.id), ['one', 'two']);
      expect(() => result.add(_product('three')), throwsUnsupportedError);
    },
  );

  test('uses background execution only at the catalog threshold', () async {
    final executor = _RecordingExecutor();
    final useCase = PrepareProductResultsUseCase(executor: executor);

    await useCase(
      List.generate(999, (index) => _product('$index')),
      query: '',
      sortOption: 'Newest',
    );
    await useCase(
      List.generate(1000, (index) => _product('$index')),
      query: '',
      sortOption: 'Newest',
    );

    expect(executor.backgroundRequests, [false, true]);
  });

  test('maps executor exceptions to a typed result failure', () async {
    final useCase = PrepareProductResultsUseCase(
      executor: const _ThrowingExecutor(),
    );

    final result = await useCase(
      [_product('one')],
      query: '',
      sortOption: 'Newest',
    );

    expect(result, isA<ApiFailure<List<ProductData>>>());
    expect(
      (result as ApiFailure<List<ProductData>>).failure.message,
      'Could not prepare products.',
    );
  });
}

List<ProductData> _data(ApiResult<List<ProductData>> result) =>
    (result as ApiSuccess<List<ProductData>>).data;

ProductData _product(
  String id, {
  String? title,
  String price = '1',
  String? subcategoryId,
  List<StoreSubcategoryData> subcategories = const [],
}) => ProductData(
  id: id,
  image: '',
  title: title ?? id,
  brand: 'Market',
  price: price,
  oldPrice: null,
  discount: '',
  tags: const [],
  subcategoryId: subcategoryId,
  subcategories: subcategories,
);

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

class _ThrowingExecutor implements ComputationExecutor {
  const _ThrowingExecutor();

  @override
  Future<R> run<Q, R>(
    R Function(Q) computation,
    Q input, {
    required bool background,
  }) => Future<R>.error(StateError('executor failed'));
}
