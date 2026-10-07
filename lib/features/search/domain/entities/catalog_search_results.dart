import '../../../store/domain/entities/category_data.dart';
import '../../../store/domain/entities/product_data.dart';
import '../../../store/domain/entities/store_data.dart';

class CatalogSearchResults {
  const CatalogSearchResults({
    this.products = const [],
    this.markets = const [],
    this.categories = const [],
    this.hasMoreProducts = false,
  });

  final List<ProductData> products;
  final List<StoreMarketData> markets;
  final List<CategoryData> categories;
  final bool hasMoreProducts;
}
