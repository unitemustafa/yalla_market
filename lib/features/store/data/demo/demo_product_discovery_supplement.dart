import '../../domain/entities/product_data.dart';
import '../../domain/usecases/prepare_product_discovery_usecase.dart';
import 'demo_shops.dart';

class DemoProductDiscoverySupplement implements ProductDiscoverySupplement {
  const DemoProductDiscoverySupplement();

  @override
  Iterable<ProductData> productsForCity(String citySlug) {
    final normalizedCity = citySlug.trim().toLowerCase();
    return MarketShops.all
        .where((shop) => shop.citySlug == normalizedCity)
        .expand((shop) => shop.products);
  }

  @override
  int? productCountForCategory(String categoryName, String citySlug) {
    final shops = MarketShops.byCategoryAndCity(categoryName, citySlug);
    if (shops.isEmpty) return null;
    return shops.fold<int>(0, (sum, shop) => sum + shop.productCount);
  }
}
