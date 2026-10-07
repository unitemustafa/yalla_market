import '../../../../core/network/api_result.dart';
import '../../../store/domain/repositories/product_repository.dart';
import '../../../store/domain/repositories/store_repository.dart';
import '../../../store/domain/services/market_shop_catalog.dart';
import '../../domain/entities/catalog_search_results.dart';
import '../../domain/repositories/catalog_search_repository.dart';

class CatalogSearchDemoRepository implements CatalogSearchRepository {
  const CatalogSearchDemoRepository(this._products, this._store, this._shops);

  final ProductRepository _products;
  final StoreRepository _store;
  final MarketShopCatalog _shops;

  @override
  Future<ApiResult<CatalogSearchResults>> search(
    String query, {
    required String citySlug,
    int page = 1,
  }) async {
    final products = await _products.searchProducts(query, citySlug: citySlug);
    final categories = await _products.getCategories();
    final store = await _store.getStore();
    return products.when(
      failure: ApiResult.failure,
      success: (products) => categories.when(
        failure: ApiResult.failure,
        success: (categories) => store.when(
          failure: ApiResult.failure,
          success: (store) {
            final normalized = query.toLowerCase();
            final localShopIds = _shops.shops
                .where((shop) => shop.citySlug == citySlug)
                .map((shop) => shop.id)
                .toSet();
            final localMarkets = store.marketsByClassificationId.values
                .expand((markets) => markets)
                .where((market) => localShopIds.contains(market.id))
                .toList(growable: false);
            return ApiResult.success(
              CatalogSearchResults(
                products: products,
                categories: categories
                    .where(
                      (category) =>
                          category.matches(query) &&
                          localMarkets.any(
                            (market) => market.classificationId == category.id,
                          ),
                    )
                    .map(
                      (category) => category.copyWith(
                        marketCount: localMarkets
                            .where(
                              (market) =>
                                  market.classificationId == category.id,
                            )
                            .length,
                      ),
                    )
                    .toList(growable: false),
                markets: localMarkets
                    .where(
                      (market) =>
                          market.name.toLowerCase().contains(normalized),
                    )
                    .toList(growable: false),
              ),
            );
          },
        ),
      ),
    );
  }
}
