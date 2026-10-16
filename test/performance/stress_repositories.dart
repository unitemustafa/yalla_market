import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/home/domain/entities/home_data.dart';
import 'package:yalla_market/features/home/domain/repositories/home_repository.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/location/domain/repositories/location_repository.dart';
import 'package:yalla_market/features/offers/domain/entities/offer_data.dart';
import 'package:yalla_market/features/offers/domain/repositories/offer_repository.dart';
import 'package:yalla_market/features/search/domain/entities/catalog_search_results.dart';
import 'package:yalla_market/features/search/domain/repositories/catalog_search_repository.dart';
import 'package:yalla_market/features/store/data/repositories/product_repository_impl.dart';
import 'package:yalla_market/features/store/domain/entities/category_data.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/domain/repositories/store_repository.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/market_wishlist_repository.dart';

import '../helpers/test_order_repository.dart';
import 'stress_fixtures.dart';

class StressProductRepository extends ProductRepositoryImpl {
  StressProductRepository(this.fixtures);
  final StressFixtures fixtures;
  @override
  Future<ApiResult<List<ProductData>>> getProducts({
    String? citySlug,
    bool forceRefresh = false,
  }) async => ApiResult.success(fixtures.products);
  @override
  Future<ApiResult<ProductData>> getProduct(
    String idOrSlug, {
    bool forceRefresh = false,
  }) async => ApiResult.success(
    fixtures.products.firstWhere((p) => p.id == idOrSlug || p.slug == idOrSlug),
  );
  @override
  Future<ApiResult<List<CategoryData>>> getCategories({
    bool forceRefresh = false,
  }) async => ApiResult.success(fixtures.categories);
}

class StressStoreRepository implements StoreRepository {
  StressStoreRepository(this.fixtures);
  final StressFixtures fixtures;
  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async =>
      ApiResult.success(fixtures.store);
  @override
  Future<ApiResult<StoreMarketData>> getMarket(String marketId) async =>
      ApiResult.success(fixtures.markets.firstWhere((m) => m.id == marketId));
  @override
  Future<ApiResult<List<StoreMarketData>>> getClassificationMarkets(
    String classificationId,
  ) async => ApiResult.success(fixtures.markets);
}

class StressHomeRepository implements HomeRepository {
  StressHomeRepository(this.fixtures);
  final StressFixtures fixtures;
  @override
  Future<ApiResult<HomeData>> getHome({bool forceRefresh = false}) async =>
      ApiResult.success(
        HomeData(
          location: null,
          offers: const [],
          categories: fixtures.categories,
          products: fixtures.products.take(5).toList(),
        ),
      );
}

class StressSearchRepository implements CatalogSearchRepository {
  StressSearchRepository(this.fixtures);
  final StressFixtures fixtures;
  @override
  Future<ApiResult<CatalogSearchResults>> search(
    String query, {
    required String citySlug,
    int page = 1,
  }) async {
    final items = fixtures.products.take(fixtures.listCount).toList();
    final start = ((page - 1) * 100).clamp(0, items.length);
    final end = (start + 100).clamp(0, items.length);
    return ApiResult.success(
      CatalogSearchResults(
        products: items.sublist(start, end),
        categories: fixtures.categories,
        markets: fixtures.markets,
        hasMoreProducts: end < items.length,
      ),
    );
  }
}

class StressWishlistRepository implements WishlistRepository {
  StressWishlistRepository(StressFixtures fixtures)
    : items = List.of(fixtures.wishlist);
  final List<WishlistItem> items;
  @override
  Future<ApiResult<List<WishlistItem>>> getItems(String userKey) async =>
      ApiResult.success(List.unmodifiable(items));
  @override
  Future<ApiResult<List<WishlistItem>>> toggleItem(
    String userKey,
    WishlistItem item,
  ) async {
    if (items.any((p) => p.productId == item.productId)) {
      items.removeWhere((p) => p.productId == item.productId);
    } else {
      items.add(item);
    }
    return ApiResult.success(List.unmodifiable(items));
  }
}

class StressMarketWishlistRepository implements MarketWishlistRepository {
  StressMarketWishlistRepository(StressFixtures fixtures)
    : items = List.of(fixtures.markets);
  final List<StoreMarketData> items;
  @override
  Future<ApiResult<List<StoreMarketData>>> getItems() async =>
      ApiResult.success(List.unmodifiable(items));
  @override
  Future<ApiResult<bool>> setFavorite(String marketId, bool favorite) async {
    if (!favorite) items.removeWhere((m) => m.id == marketId);
    return ApiResult.success(favorite);
  }
}

class StressOrderRepository extends TestOrderRepository {
  StressOrderRepository(this.fixtures);
  final StressFixtures fixtures;
  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async =>
      ApiResult.success(fixtures.orders);
}

class StressOfferRepository implements OfferRepository {
  @override
  Future<ApiResult<List<OfferData>>> getOffers() async =>
      const ApiResult.success([]);
}

class StressLocationRepository extends LocationRepository {
  static const city = CityData(name: 'Cairo', slug: 'cairo');
  @override
  Future<ApiResult<CityData?>> getSelectedCity() async =>
      const ApiResult.success(city);
  @override
  Future<ApiResult<List<CityData>>> getAvailableCities() async =>
      const ApiResult.success([city]);
  @override
  Future<ApiResult<CityData>> saveSelectedCity(CityData city) async =>
      ApiResult.success(city);
  @override
  Future<ApiResult<CityData>> useCurrentLocation() async =>
      const ApiResult.success(city);
}
