import 'product_data.dart';

enum StoreProductSort {
  name('name', 'Name'),
  priceAsc('price_asc', 'Lower Price'),
  priceDesc('price_desc', 'Higher Price'),
  newest('newest', 'Newest');

  const StoreProductSort(this.apiValue, this.label);
  final String apiValue;
  final String label;
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
