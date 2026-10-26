import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../entities/store_product_page.dart';
import '../repositories/store_products_repository.dart';

class GetStoreProductsUseCase {
  const GetStoreProductsUseCase(this._repository);
  final StoreProductsRepository _repository;
  bool get supportsBatchedRefresh =>
      _repository is BatchedStoreProductsRepository;

  Future<ApiResult<StoreProductPage>> call(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  }) {
    if (marketId.trim().isEmpty || page < 1 || pageSize < 1 || pageSize > 100) {
      return Future.value(
        const ApiResult.failure(
          ValidationFailure('Invalid store products request.'),
        ),
      );
    }
    return _repository.getProducts(
      marketId.trim(),
      page: page,
      pageSize: pageSize,
      query: query.trim(),
      subcategoryId: subcategoryId?.trim(),
      sort: sort,
    );
  }
}
