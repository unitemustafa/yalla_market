import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/domain/entities/store_product_page.dart';
import 'package:yalla_market/features/store/domain/repositories/store_products_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_products_usecase.dart';

void main() {
  test(
    'rejects invalid store product requests without calling repository',
    () async {
      final repository = _Repository();
      final useCase = GetStoreProductsUseCase(repository);

      for (final request in [
        (' ', 1, 30),
        ('market', 0, 30),
        ('market', 1, 101),
      ]) {
        final result = await useCase(
          request.$1,
          page: request.$2,
          pageSize: request.$3,
        );
        expect(result, isA<ApiFailure<StoreProductPage>>());
      }
      expect(repository.calls, isEmpty);
    },
  );

  test('trims the market and query and forwards default page size', () async {
    final repository = _Repository();
    await GetStoreProductsUseCase(repository)(
      ' market ',
      query: ' apples ',
      subcategoryId: 'fruit',
      sort: StoreProductSort.priceAsc,
    );

    expect(repository.calls, [
      ('market', 1, 30, 'apples', 'fruit', StoreProductSort.priceAsc),
    ]);
  });
}

class _Repository implements StoreProductsRepository {
  final calls = <(String, int, int, String, String?, StoreProductSort)>[];
  @override
  Future<ApiResult<StoreProductPage>> getProducts(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  }) async {
    calls.add((marketId, page, pageSize, query, subcategoryId, sort));
    return const ApiResult.success(
      StoreProductPage(products: [], count: 0, hasMore: false),
    );
  }
}
