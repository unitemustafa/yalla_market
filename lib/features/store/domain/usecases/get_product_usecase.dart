import '../../../../core/network/api_result.dart';
import '../entities/product_data.dart';
import '../repositories/product_repository.dart';

class GetProductUseCase {
  const GetProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<ApiResult<ProductData>> call(
    String idOrSlug, {
    bool forceRefresh = false,
  }) {
    return _repository.getProduct(idOrSlug, forceRefresh: forceRefresh);
  }
}
