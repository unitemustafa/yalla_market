import '../../../../core/network/api_result.dart';
import '../entities/catalog_search_results.dart';

export '../entities/catalog_search_results.dart' show CatalogSection;

abstract interface class PagedCatalogSearchRepository {
  Future<ApiResult<CatalogSearchResults>> searchSection(
    String query, {
    required String citySlug,
    required CatalogSection section,
    int page = 1,
  });
}

abstract interface class CatalogSearchRepository {
  Future<ApiResult<CatalogSearchResults>> search(
    String query, {
    required String citySlug,
    int page = 1,
  });
}
