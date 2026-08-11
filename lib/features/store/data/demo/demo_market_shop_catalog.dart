import '../../domain/entities/category_data.dart';
import '../../domain/entities/market_shop_data.dart' as domain;
import '../../domain/services/market_shop_catalog.dart';
import 'demo_categories.dart';
import 'demo_shops.dart' as demo;

class DemoMarketShopCatalog implements MarketShopCatalog {
  const DemoMarketShopCatalog();

  @override
  List<domain.MarketShopData> get shops =>
      demo.MarketShops.all.map(_mapShop).toList(growable: false);

  @override
  List<domain.MarketShopData> byCategoryAndCity(
    String categoryName,
    String citySlug,
  ) {
    return demo.MarketShops.byCategoryAndCity(
      categoryName,
      citySlug,
    ).map(_mapShop).toList(growable: false);
  }

  @override
  domain.MarketShopData? byId(String id) {
    final shop = demo.MarketShops.byId(id);
    return shop == null ? null : _mapShop(shop);
  }

  @override
  bool categoryHasLocalShops(String categoryName) {
    return MarketCategories.hasLocalShops(categoryName);
  }

  @override
  CategoryData? categoryByName(String categoryName) {
    final normalized = categoryName.trim().toLowerCase();
    for (final category in MarketCategories.all) {
      if (category.name.trim().toLowerCase() != normalized) continue;
      final id = _slug(category.name);
      return CategoryData(
        id: id,
        name: category.name,
        slug: id,
        productCount: _count(category.count),
        image: category.image,
        galleryImages: category.galleryImages,
        accentColorValue: category.color.toARGB32(),
        keywords: category.keywords,
      );
    }
    return null;
  }

  domain.MarketShopData _mapShop(demo.MarketShopData shop) {
    return domain.MarketShopData(
      id: shop.id,
      name: shop.name,
      categoryName: shop.categoryName,
      citySlug: shop.citySlug,
      cityName: shop.cityName,
      logo: shop.logo,
      galleryImages: shop.galleryImages,
      accentColorValue: shop.accentColorValue,
      rating: shop.rating,
      deliveryEstimate: shop.deliveryEstimate,
      products: shop.products,
    );
  }

  int _count(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
