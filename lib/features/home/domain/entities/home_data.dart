import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../offers/domain/entities/offer_data.dart';
import '../../../store/domain/entities/category_data.dart';
import '../../../store/domain/entities/product_data.dart';

typedef HomeOfferData = OfferData;
typedef HomeOfferMarketData = OfferMarketData;

class HomeData {
  const HomeData({
    required this.location,
    required this.offers,
    required this.categories,
    required this.products,
  });

  final HomeLocationData? location;
  final List<HomeOfferData> offers;
  final List<CategoryData> categories;
  final List<ProductData> products;

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      location: json['location'] is Map<String, dynamic>
          ? HomeLocationData.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      offers: _listFromJson(
        json['offers'],
      ).map(OfferData.fromJson).toList(growable: false),
      categories: _listFromJson(
        json['market_classifications'],
      ).map(_categoryFromClassification).toList(growable: false),
      products: _listFromJson(json['products'])
          .map(ProductData.fromJson)
          .map(_productWithResolvedImage)
          .toList(growable: false),
    );
  }
}

class HomeLocationData {
  const HomeLocationData({
    required this.addressId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String addressId;
  final String name;
  final String latitude;
  final String longitude;

  factory HomeLocationData.fromJson(Map<String, dynamic> json) {
    return HomeLocationData(
      addressId: json['address_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
    );
  }
}

List<Map<String, dynamic>> _listFromJson(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

CategoryData _categoryFromClassification(Map<String, dynamic> json) {
  final markets = json['markets'] is List ? json['markets'] as List : const [];
  final id = json['id']?.toString() ?? '';
  final name = json['name']?.toString() ?? '';
  return CategoryData(
    id: id,
    name: name,
    slug: _slugFrom(name.isEmpty ? id : name),
    productCount: _intFromJson(json['product_count']) ?? markets.length,
    image: _resolveImage(json['image']),
    galleryImages: const [],
    accentColorValue: _accentColorFor(id),
    keywords: [name],
  );
}

ProductData _productWithResolvedImage(ProductData product) {
  return ProductData(
    id: product.id,
    code: product.code,
    slug: product.slug,
    image: _resolveImage(product.image),
    images: product.images,
    title: product.title,
    brand: product.brand,
    price: product.price,
    oldPrice: product.oldPrice,
    discount: product.discount,
    tags: product.tags,
    isFamilySafe: product.isFamilySafe,
    citySlug: product.citySlug,
    cityName: product.cityName,
    visibilityMode: product.visibilityMode,
    regionSlugs: product.regionSlugs,
    regionNames: product.regionNames,
    categoryId: product.categoryId,
    marketId: product.marketId,
    marketClassificationId: product.marketClassificationId,
    variants: product.variants,
    attributes: product.attributes,
    additions: product.additions,
    description: product.description,
    isAvailable: product.isAvailable,
    theme: product.theme,
    isPopular: product.isPopular,
    offerVariantId: product.offerVariantId,
    offerQuantity: product.offerQuantity,
    applyProductDiscount: product.applyProductDiscount,
  );
}

String _resolveImage(Object? value) {
  final image = value?.toString().trim() ?? '';
  if (image.isEmpty) return AppAssets.temporaryMarketPlaceholder;
  final uri = Uri.tryParse(image);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return image;
  }
  if (image.startsWith('/')) {
    final baseUrl = ApiEndpoints.rootBaseUrl;
    if (baseUrl.isNotEmpty) return '$baseUrl$image';
  }
  return image;
}

String _slugFrom(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

int? _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

int _accentColorFor(String seed) {
  const colors = [0xFF013C7E, 0xFF22C55E, 0xFFF59E0B, 0xFFEF4444];
  final index = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return colors[index % colors.length];
}
