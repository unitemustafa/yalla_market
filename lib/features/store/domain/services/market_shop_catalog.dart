import '../entities/category_data.dart';
import '../entities/market_shop_data.dart';

abstract interface class MarketShopCatalog {
  List<MarketShopData> get shops;

  List<MarketShopData> byCategoryAndCity(String categoryName, String citySlug);

  MarketShopData? byId(String id);

  bool categoryHasLocalShops(String categoryName);

  CategoryData? categoryByName(String categoryName);
}

class EmptyMarketShopCatalog implements MarketShopCatalog {
  const EmptyMarketShopCatalog();

  @override
  List<MarketShopData> get shops => const [];

  @override
  List<MarketShopData> byCategoryAndCity(
    String categoryName,
    String citySlug,
  ) => const [];

  @override
  MarketShopData? byId(String id) => null;

  @override
  bool categoryHasLocalShops(String categoryName) => false;

  @override
  CategoryData? categoryByName(String categoryName) => null;
}
