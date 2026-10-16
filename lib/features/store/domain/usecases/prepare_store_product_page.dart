import '../entities/product_data.dart';
import '../entities/store_product_page.dart';

/// Mirrors the server contract for the explicitly enabled demo catalog.
StoreProductPage prepareStoreProductPage(
  List<ProductData> products, {
  required int page,
  required int pageSize,
  required String query,
  required String? subcategoryId,
  required StoreProductSort sort,
}) {
  final q = query.trim().toLowerCase();
  final category = subcategoryId?.trim() ?? '';
  final filtered = products
      .where(
        (p) =>
            (category.isEmpty ||
                p.subcategoryId == category ||
                p.subcategories.any((c) => c.id == category)) &&
            (p.matches(q) || p.description.toLowerCase().contains(q)),
      )
      .toList();
  if (sort != StoreProductSort.newest) {
    filtered.sort((a, b) {
      final comparison = switch (sort) {
        StoreProductSort.name => a.title.compareTo(b.title),
        StoreProductSort.priceAsc => a.priceValue.compareTo(b.priceValue),
        StoreProductSort.priceDesc => b.priceValue.compareTo(a.priceValue),
        StoreProductSort.newest => 0,
      };
      return comparison == 0 ? a.id.compareTo(b.id) : comparison;
    });
  }
  final start = (page - 1) * pageSize;
  return StoreProductPage(
    products: List.unmodifiable(filtered.skip(start).take(pageSize)),
    count: filtered.length,
    hasMore: start + pageSize < filtered.length,
  );
}
