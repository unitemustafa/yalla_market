import '../../../../core/network/api_result.dart';
import '../entities/category_data.dart';
import '../repositories/product_repository.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final ProductRepository _repository;

  Future<ApiResult<List<CategoryData>>> call({bool forceRefresh = false}) {
    return _repository.getCategories(forceRefresh: forceRefresh);
  }
}
