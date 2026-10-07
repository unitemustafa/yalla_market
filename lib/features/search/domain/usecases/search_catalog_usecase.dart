import '../../../../core/network/api_result.dart';
import '../entities/catalog_search_results.dart';
import '../repositories/catalog_search_repository.dart';

class SearchCatalogUseCase {
  const SearchCatalogUseCase(this._repository);

  final CatalogSearchRepository _repository;

  Future<ApiResult<CatalogSearchResults>> call(
    String query, {
    required String citySlug,
    int page = 1,
  }) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return Future.value(const ApiResult.success(CatalogSearchResults()));
    }
    return _repository.search(normalized, citySlug: citySlug, page: page);
  }
}
