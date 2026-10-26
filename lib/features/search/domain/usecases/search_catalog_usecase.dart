import '../../../../core/network/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../entities/catalog_search_results.dart';
import '../repositories/catalog_search_repository.dart';

class SearchCatalogUseCase {
  const SearchCatalogUseCase(this._repository);

  final CatalogSearchRepository _repository;

  Future<ApiResult<CatalogSearchResults>> section(
    String query, {
    required String citySlug,
    required CatalogSection section,
    int page = 1,
  }) {
    if (page < 1) {
      return Future.value(
        const ApiResult.failure(ValidationFailure('Invalid search page.')),
      );
    }
    if (query.trim().isEmpty) {
      return Future.value(const ApiResult.success(CatalogSearchResults()));
    }
    final repository = _repository;
    if (repository is PagedCatalogSearchRepository) {
      return (repository as PagedCatalogSearchRepository).searchSection(
        query.trim(),
        citySlug: citySlug,
        section: section,
        page: page,
      );
    }
    return call(query, citySlug: citySlug, page: page);
  }

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
