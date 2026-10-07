import '../../../../core/network/api_result.dart';
import '../entities/catalog_search_results.dart';

abstract interface class CatalogSearchRepository {
  Future<ApiResult<CatalogSearchResults>> search(
    String query, {
    required String citySlug,
    int page = 1,
  });
}
