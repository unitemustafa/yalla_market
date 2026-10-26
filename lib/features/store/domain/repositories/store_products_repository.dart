import '../../../../core/network/api_result.dart';
import '../entities/store_product_page.dart';

/// Servers supporting page sizes that are multiples of the normal 30 items.
abstract interface class BatchedStoreProductsRepository {}

abstract interface class StoreProductsRepository {
  Future<ApiResult<StoreProductPage>> getProducts(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  });
}
