import 'product_data.dart';

enum StoreProductSort {
  name('name'),
  priceAsc('price_asc'),
  priceDesc('price_desc'),
  newest('newest');

  const StoreProductSort(this.apiValue);
  final String apiValue;
}

class StoreProductPage {
  const StoreProductPage({
    required this.products,
    required this.count,
    required this.hasMore,
  });
  final List<ProductData> products;
  final int count;
  final bool hasMore;
}
