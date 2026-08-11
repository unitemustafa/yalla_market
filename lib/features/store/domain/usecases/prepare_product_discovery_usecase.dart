import '../entities/category_data.dart';
import '../entities/product_data.dart';

abstract interface class ProductDiscoverySupplement {
  Iterable<ProductData> productsForCity(String citySlug);

  int? productCountForCategory(String categoryName, String citySlug);
}

class EmptyProductDiscoverySupplement implements ProductDiscoverySupplement {
  const EmptyProductDiscoverySupplement();

  @override
  Iterable<ProductData> productsForCity(String citySlug) => const [];

  @override
  int? productCountForCategory(String categoryName, String citySlug) => null;
}

class PrepareProductDiscoveryUseCase {
  const PrepareProductDiscoveryUseCase({
    ProductDiscoverySupplement supplement =
        const EmptyProductDiscoverySupplement(),
  }) : _supplement = supplement;

  final ProductDiscoverySupplement _supplement;

  List<ProductData> products(
    List<ProductData> products, {
    required String citySlug,
    String query = '',
  }) {
    final combined = <ProductData>[
      ...products,
      ..._supplement.productsForCity(citySlug),
    ];
    final normalizedQuery = query.trim();
    final matching = normalizedQuery.isEmpty
        ? combined
        : combined
              .where((product) => product.matches(normalizedQuery))
              .toList(growable: false);
    return _dedupe(matching);
  }

  List<CategoryData> categoriesWithProductCounts({
    required List<CategoryData> categories,
    required List<ProductData> products,
    required String citySlug,
  }) {
    return categories
        .map(
          (category) => category.copyWith(
            productCount: _productCountForCategory(
              category: category,
              products: products,
              citySlug: citySlug,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<ProductData> _dedupe(Iterable<ProductData> products) {
    final seen = <String>{};
    final result = <ProductData>[];
    for (final product in products) {
      final normalizedId = product.id.trim().toLowerCase();
      final key = normalizedId.isNotEmpty
          ? normalizedId
          : product.slug?.trim().toLowerCase() ??
                '${_normalize(product.brand)}::${_normalize(product.title)}';
      if (seen.add(key)) result.add(product);
    }
    return List.unmodifiable(result);
  }

  int _productCountForCategory({
    required CategoryData category,
    required List<ProductData> products,
    required String citySlug,
  }) {
    final supplementalCount = _supplement.productCountForCategory(
      category.name,
      citySlug,
    );
    if (supplementalCount != null) return supplementalCount;

    return products
        .where((product) => _productBelongsToCategory(product, category))
        .length;
  }

  bool _productBelongsToCategory(ProductData product, CategoryData category) {
    final categoryTerms = {
      category.name,
      category.slug,
      ...category.keywords,
    }.map(_normalize).where((term) => term.isNotEmpty).toSet();
    if (categoryTerms.isEmpty) return false;
    if (categoryTerms.contains(_normalize(product.brand))) return true;
    return product.tags.any((tag) => categoryTerms.contains(_normalize(tag)));
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
