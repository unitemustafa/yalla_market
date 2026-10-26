import '../../../store/domain/entities/category_data.dart';
import '../../../store/domain/entities/product_data.dart';
import '../../../store/domain/entities/store_data.dart';

enum CatalogSection { all, products, markets, categories }

class CatalogSearchResults {
  const CatalogSearchResults({
    this.products = const [],
    this.markets = const [],
    this.categories = const [],
    this.hasMoreProducts = false,
    this.hasMoreMarkets = false,
    this.hasMoreCategories = false,
  });

  final List<ProductData> products;
  final List<StoreMarketData> markets;
  final List<CategoryData> categories;
  final bool hasMoreProducts;
  final bool hasMoreMarkets;
  final bool hasMoreCategories;
}
