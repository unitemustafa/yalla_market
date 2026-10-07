import 'package:dio/dio.dart';

import '../../../../core/cache/persistent_json_cache.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/region_required_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../store/domain/entities/category_data.dart';
import '../../../store/domain/entities/product_data.dart';
import '../../../store/domain/entities/store_data.dart';
import '../../domain/entities/catalog_search_results.dart';
import '../../domain/repositories/catalog_search_repository.dart';

class CatalogSearchRemoteRepository implements CatalogSearchRepository {
  const CatalogSearchRemoteRepository(
    this._apiClient, {
    PersistentJsonCache? cache,
  }) : _cache = cache;

  final ApiClient _apiClient;
  final PersistentJsonCache? _cache;

  @override
  Future<ApiResult<CatalogSearchResults>> search(
    String query, {
    required String citySlug,
    int page = 1,
  }) async {
    try {
      // The server scopes all three result types to the saved browsing region.
      final payload = await _apiClient.get<Map<String, dynamic>>(
        '/home/search/',
        queryParameters: {'q': query, 'include': 'all', 'page': page},
      );
      return ApiResult.success(
        CatalogSearchResults(
          products: _items(
            payload['results'],
          ).map(ProductData.fromJson).toList(growable: false),
          markets: _items(
            payload['markets'],
            required: page == 1,
          ).map(StoreMarketData.fromJson).toList(growable: false),
          categories: _items(
            payload['categories'],
            required: page == 1,
          ).map(CategoryData.fromJson).toList(growable: false),
          hasMoreProducts: payload['next'] != null,
        ),
      );
    } on DioException catch (error) {
      if (isRegionRequiredPayload(error.response?.data)) {
        return const ApiResult.failure(
          ValidationFailure(regionRequiredMessage),
        );
      }
      if (page == 1 &&
          (error.response == null ||
              (error.response!.statusCode ?? 0) >= 500)) {
        final cached = await _cachedResults(query, citySlug);
        if (cached != null) return cached;
      }
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(UnknownFailure('Search failed'));
    }
  }

  Future<ApiResult<CatalogSearchResults>?> _cachedResults(
    String query,
    String citySlug,
  ) async {
    final cache = _cache;
    if (cache == null) return null;
    try {
      // Reuse the existing city catalog cache without persisting search queries.
      final entries = await Future.wait([
        cache.read('products.$citySlug'),
        cache.read('classifications.$citySlug'),
        cache.read('store.v5.$citySlug'),
      ]);
      if (entries.every((entry) => entry == null)) return null;
      final productPayload = entries[0]?.value;
      final classificationPayload = entries[1]?.value;
      final storePayload = entries[2]?.value;
      final products = productPayload is Map<String, dynamic>
          ? productPayload['results'] ??
                productPayload['items'] ??
                productPayload['products']
          : productPayload;
      final categories = storePayload is Map<String, dynamic>
          ? storePayload['market_classifications']
          : classificationPayload is Map<String, dynamic>
          ? classificationPayload['market_classifications'] ??
                classificationPayload['common_categories'] ??
                classificationPayload['categories']
          : classificationPayload;
      final normalized = query.toLowerCase();
      final seen = <String>{};
      final markets = storePayload is Map<String, dynamic>
          ? _items(storePayload['market_classifications'], required: false)
                .expand(
                  (category) => _items(category['markets'], required: false),
                )
                .map(StoreMarketData.fromJson)
                .where(
                  (market) =>
                      market.status == 'active' &&
                      market.name.toLowerCase().contains(normalized) &&
                      seen.add(market.id),
                )
                .toList(growable: false)
          : <StoreMarketData>[];
      return ApiResult.success(
        CatalogSearchResults(
          products: _items(products, required: false)
              .map(ProductData.fromJson)
              .where((product) => product.matches(query))
              .toList(growable: false),
          categories: _items(categories, required: false)
              .map(CategoryData.fromJson)
              .where((category) => category.matches(query))
              .toList(growable: false),
          markets: markets,
        ),
        origin: DataOrigin.cache,
        savedAt: entries.whereType<CachedJsonEntry>().first.savedAt,
      );
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _items(Object? value, {bool required = true}) {
    if (!required && value == null) return const [];
    if (value is! List || value.any((item) => item is! Map<String, dynamic>)) {
      throw const FormatException('Invalid search results.');
    }
    final items = value.cast<Map<String, dynamic>>();
    if (items.any(
      (item) =>
          (item['id']?.toString() ?? '').isEmpty ||
          (item['name']?.toString() ?? '').trim().isEmpty,
    )) {
      throw const FormatException('Invalid search item.');
    }
    return items;
  }
}
