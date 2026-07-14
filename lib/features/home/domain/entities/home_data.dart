import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../store/domain/entities/category_data.dart';
import '../../../store/domain/entities/product_data.dart';

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
      ).map(HomeOfferData.fromJson).toList(growable: false),
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

class HomeOfferData {
  const HomeOfferData({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.type,
    required this.discount,
    required this.startsAt,
    required this.endsAt,
    this.marketId = '',
    required this.marketName,
    this.isMultiMarket = false,
    this.marketCount = 0,
    this.markets = const [],
    this.marketNamesSummary = '',
    this.showInGeneral = true,
    this.serviceCityIds = const [],
    this.serviceCityNames = const [],
    this.announcementUrl = '',
    this.announcementCtaLabel = '',
    this.announcementPriority = 0,
    this.announcementDisplaySeconds = 15,
    required this.products,
  });

  final String id;
  final String title;
  final String description;
  final String image;
  final String type;
  final String discount;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String marketId;
  final String marketName;
  final bool isMultiMarket;
  final int marketCount;
  final List<HomeOfferMarketData> markets;
  final String marketNamesSummary;
  final bool showInGeneral;
  final List<int> serviceCityIds;
  final List<String> serviceCityNames;
  final String announcementUrl;
  final String announcementCtaLabel;
  final int announcementPriority;
  final int announcementDisplaySeconds;
  final List<ProductData> products;

  factory HomeOfferData.fromJson(Map<String, dynamic> json) {
    final market = json['market'] is Map<String, dynamic>
        ? json['market'] as Map<String, dynamic>
        : null;

    return HomeOfferData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: _resolveImage(json['image']),
      type: json['type']?.toString() ?? '',
      discount: json['discount']?.toString() ?? '',
      startsAt: DateTime.tryParse(json['start_time']?.toString() ?? ''),
      endsAt: DateTime.tryParse(json['end_time']?.toString() ?? ''),
      marketId:
          json['market_id']?.toString() ?? market?['id']?.toString() ?? '',
      marketName: market?['name']?.toString() ?? '',
      isMultiMarket: _boolFromJson(json['is_multi_market']) ?? false,
      marketCount: _intFromJson(json['market_count']) ?? 0,
      markets: _listFromJson(
        json['markets'],
      ).map(HomeOfferMarketData.fromJson).toList(growable: false),
      marketNamesSummary: json['market_names_summary']?.toString() ?? '',
      showInGeneral: _boolFromJson(json['show_in_general']) ?? true,
      serviceCityIds: _serviceCityIdsFromJson(json),
      serviceCityNames: _serviceCityNamesFromJson(json),
      announcementUrl: json['announcement_url']?.toString() ?? '',
      announcementCtaLabel: json['announcement_cta_label']?.toString() ?? '',
      announcementPriority: _intFromJson(json['announcement_priority']) ?? 0,
      announcementDisplaySeconds:
          _intFromJson(json['announcement_display_seconds']) ?? 15,
      products: _listFromJson(json['products'])
          .map(ProductData.fromJson)
          .map(_productWithResolvedImage)
          .toList(growable: false),
    );
  }

  String get discountLabel {
    final value = discount.trim();
    if (value.isEmpty) return '';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return '';
    final text = parsed == parsed.roundToDouble()
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(1);
    return '$text% off';
  }
}

class HomeOfferMarketData {
  const HomeOfferMarketData({
    required this.id,
    required this.name,
    required this.branch,
  });

  final String id;
  final String name;
  final String branch;

  factory HomeOfferMarketData.fromJson(Map<String, dynamic> json) {
    return HomeOfferMarketData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
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

bool? _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return null;
}

List<int> _serviceCityIdsFromJson(Map<String, dynamic> json) {
  final ids = <int>{};
  final direct = json['service_city_ids'];
  if (direct is List) {
    for (final item in direct) {
      final id = _intFromJson(item);
      if (id != null && id > 0) ids.add(id);
    }
  }

  for (final city in _listFromJson(json['service_cities'])) {
    final id = _intFromJson(city['id']);
    if (id != null && id > 0) ids.add(id);
  }

  return ids.toList(growable: false);
}

List<String> _serviceCityNamesFromJson(Map<String, dynamic> json) {
  return _listFromJson(json['service_cities'])
      .map((city) => city['name']?.toString().trim() ?? '')
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
}

int _accentColorFor(String seed) {
  const colors = [0xFF4F60F6, 0xFF22C55E, 0xFFF59E0B, 0xFFEF4444];
  final index = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return colors[index % colors.length];
}
