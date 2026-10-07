import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/search/data/repositories/catalog_search_demo_repository.dart';
import 'package:yalla_market/features/store/data/demo/demo_market_shop_catalog.dart';
import 'package:yalla_market/features/store/data/repositories/product_repository_impl.dart';
import 'package:yalla_market/features/store/data/repositories/store_repository_impl.dart';

void main() {
  const catalog = DemoMarketShopCatalog();
  final repository = CatalogSearchDemoRepository(
    ProductRepositoryImpl(),
    StoreRepositoryImpl(),
    catalog,
  );

  test('demo shop search is scoped to its city', () async {
    final shop = catalog.shops.first;
    final result = await repository.search(shop.name, citySlug: shop.citySlug);
    final results = (result as ApiSuccess).data;
    expect(results.markets.any((market) => market.id == shop.id), isTrue);
    for (final market in results.markets) {
      expect(catalog.byId(market.id)!.citySlug, shop.citySlug);
    }
    final remote = await repository.search(shop.name, citySlug: 'unknown-city');
    expect((remote as ApiSuccess).data.markets, isEmpty);
  });

  test('demo category search returns categories with local shops', () async {
    final shop = catalog.shops.first;
    final result = await repository.search(
      shop.categoryName,
      citySlug: shop.citySlug,
    );
    final categories = (result as ApiSuccess).data.categories;
    expect(categories, isNotEmpty);
    expect(categories.first.name, shop.categoryName);
    expect(
      categories.first.marketCount,
      catalog.byCategoryAndCity(shop.categoryName, shop.citySlug).length,
    );
    final remote = await repository.search(
      shop.categoryName,
      citySlug: 'unknown-city',
    );
    expect((remote as ApiSuccess).data.categories, isEmpty);
  });
}
