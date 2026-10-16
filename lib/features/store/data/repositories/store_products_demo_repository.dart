import '../../../../core/network/api_result.dart';
import '../../domain/entities/store_product_page.dart';
import '../../domain/repositories/store_products_repository.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/usecases/prepare_store_product_page.dart';

class StoreProductsDemoRepository implements StoreProductsRepository {
  const StoreProductsDemoRepository(this._stores);
  final StoreRepository _stores;
  @override
  Future<ApiResult<StoreProductPage>> getProducts(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  }) async {
    final result = await _stores.getMarket(marketId);
    return switch (result) {
      ApiSuccess(:final data) => ApiResult.success(
        prepareStoreProductPage(
          data.products,
          page: page,
          pageSize: pageSize,
          query: query,
          subcategoryId: subcategoryId,
          sort: sort,
        ),
      ),
      ApiFailure(:final failure) => ApiResult.failure(failure),
    };
  }
}
