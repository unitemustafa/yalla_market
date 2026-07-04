import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/api_endpoints.dart';

class ProductVariantData {
  const ProductVariantData({
    required this.id,
    required this.price,
    this.sku,
    this.attributeValues = const {},
  });

  final String id;
  final String price;
  final String? sku;
  final Map<String, String> attributeValues;

  factory ProductVariantData.fromJson(Map<String, dynamic> json) {
    return ProductVariantData(
      id: json['id']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      sku: json['sku']?.toString(),
      attributeValues: _attributeValuesFromJson(
        json['attributeValues'] ??
            json['attribute_values'] ??
            json['attributes'] ??
            json['options'],
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'price': price,
      'sku': sku,
      'attributeValues': attributeValues,
    };
  }
}

class ProductData {
  const ProductData({
    this.id,
    this.code,
    this.slug,
    required this.image,
    required this.title,
    required this.brand,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.tags,
    this.description = '',
    this.isAvailable = true,
    this.isFamilySafe = true,
    this.citySlug,
    this.cityName,
    this.visibilityMode,
    this.regionSlugs = const [],
    this.regionNames = const [],
    this.categoryId,
    this.marketId,
    this.marketClassificationId,
    this.variants = const [],
  });

  final String? id;
  final String? code;
  final String? slug;
  final String image;
  final String title;
  final String brand;
  final String price;
  final String? oldPrice;
  final String discount;
  final List<String> tags;
  final String description;
  final bool isAvailable;
  final bool isFamilySafe;
  final String? citySlug;
  final String? cityName;
  final String? visibilityMode;
  final List<String> regionSlugs;
  final List<String> regionNames;
  final String? categoryId;
  final String? marketId;
  final String? marketClassificationId;
  final List<ProductVariantData> variants;

  ProductVariantData? get defaultVariant =>
      variants.isEmpty ? null : variants.first;

  String? get defaultVariantId {
    final id = defaultVariant?.id.trim();
    return id == null || id.isEmpty ? null : id;
  }

  String? get defaultVariantPrice {
    final price = defaultVariant?.price.trim();
    return price == null || price.isEmpty ? null : price;
  }

  bool get isGeneralVisibility {
    final mode = visibilityMode?.trim().toLowerCase();
    return mode == null ||
        mode.isEmpty ||
        mode == 'general' ||
        mode == 'all' ||
        (regionSlugs.isEmpty && (citySlug == null || citySlug!.trim().isEmpty));
  }

  List<String> get effectiveRegionSlugs {
    if (regionSlugs.isNotEmpty) return regionSlugs;
    final legacyCity = citySlug?.trim().toLowerCase();
    if (legacyCity == null || legacyCity.isEmpty) return const [];
    return [legacyCity];
  }

  factory ProductData.fromJson(Map<String, dynamic> json) {
    final tags = _stringList(json['tags']);
    final category = _mapFromJson(json['category']);
    final market = _mapFromJson(json['market']);
    final variants = json['variants'] is List
        ? json['variants'] as List
        : const [];
    final parsedVariants = variants
        .whereType<Map<String, dynamic>>()
        .map(ProductVariantData.fromJson)
        .where((variant) => variant.id.isNotEmpty || variant.price.isNotEmpty)
        .toList(growable: false);
    final firstVariant = parsedVariants.firstOrNull;
    final variantPrices = parsedVariants
        .map((variant) => variant.price)
        .where((price) => price.trim().isNotEmpty)
        .toList(growable: false);
    final price =
        json['price']?.toString() ??
        (variantPrices.isEmpty ? '' : variantPrices.join(' - '));

    return ProductData(
      id: json['id']?.toString(),
      code:
          json['code']?.toString() ??
          json['productCode']?.toString() ??
          json['product_code']?.toString() ??
          firstVariant?.sku,
      slug: json['slug']?.toString(),
      image: _resolveImage(json['image'] ?? json['imageUrl']),
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      brand:
          json['brand']?.toString() ??
          market?['name']?.toString() ??
          category?['name']?.toString() ??
          '',
      price: price,
      oldPrice: json['oldPrice']?.toString() ?? json['old_price']?.toString(),
      discount: json['discount']?.toString() ?? '',
      tags: [
        ...tags,
        if (category?['name'] != null) category!['name'].toString(),
        if (market?['name'] != null) market!['name'].toString(),
      ],
      description: json['description']?.toString() ?? '',
      isAvailable:
          _boolFromJson(json['isAvailable'] ?? json['is_available']) ?? true,
      isFamilySafe: _familySafeFromJson(json, tags),
      citySlug: json['citySlug']?.toString() ?? json['city_slug']?.toString(),
      cityName: json['cityName']?.toString() ?? json['city_name']?.toString(),
      visibilityMode:
          json['visibilityMode']?.toString() ??
          json['visibility_mode']?.toString(),
      regionSlugs: _stringList(
        json['regionSlugs'] ?? json['region_slugs'] ?? json['regions'],
      ),
      regionNames: _stringList(json['regionNames'] ?? json['region_names']),
      categoryId:
          json['categoryId']?.toString() ??
          json['category_id']?.toString() ??
          category?['id']?.toString(),
      marketId:
          json['marketId']?.toString() ??
          json['market_id']?.toString() ??
          market?['id']?.toString(),
      marketClassificationId:
          json['marketClassificationId']?.toString() ??
          json['market_classification_id']?.toString() ??
          market?['classification_id']?.toString(),
      variants: parsedVariants,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'code': code,
      'slug': slug,
      'image': image,
      'title': title,
      'brand': brand,
      'price': price,
      'oldPrice': oldPrice,
      'discount': discount,
      'tags': tags,
      'description': description,
      'isAvailable': isAvailable,
      'isFamilySafe': isFamilySafe,
      'citySlug': citySlug,
      'cityName': cityName,
      'visibilityMode': visibilityMode,
      'regionSlugs': regionSlugs,
      'regionNames': regionNames,
      'categoryId': categoryId,
      'marketId': marketId,
      'marketClassificationId': marketClassificationId,
      'variants': variants.map((variant) => variant.toJson()).toList(),
    };
  }

  double get priceValue {
    final firstPrice = price.split('-').first.trim();
    return double.tryParse(
          firstPrice.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', ''),
        ) ??
        0.0;
  }

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    return title.toLowerCase().contains(normalizedQuery) ||
        (code?.toLowerCase().contains(normalizedQuery) ?? false) ||
        brand.toLowerCase().contains(normalizedQuery) ||
        tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
  }

  bool isAllowedBySafeMode(bool safeMode) {
    return !safeMode || isFamilySafe;
  }
}

Map<String, dynamic>? _mapFromJson(Object? value) {
  if (value is Map<String, dynamic>) return value;
  return null;
}

Map<String, String> _attributeValuesFromJson(Object? value) {
  if (value is List) return _attributeValuesFromList(value);
  if (value is Map) {
    final attributes = <String, String>{};
    for (final entry in value.entries) {
      final key = entry.key.toString().trim();
      final attributeValue = entry.value?.toString().trim() ?? '';
      if (key.isEmpty || attributeValue.isEmpty) continue;
      attributes[key] = attributeValue;
    }
    return attributes;
  }
  return const {};
}

Map<String, String> _attributeValuesFromList(List<Object?> values) {
  final attributes = <String, String>{};

  for (final value in values) {
    if (value is! Map) continue;
    final attribute = value['attribute'];
    final option = value['option'];
    final attributeName =
        _stringFromJson(value['attribute_name'] ?? value['attributeName']) ??
        (attribute is Map
            ? _stringFromJson(attribute['name'] ?? attribute['attributeName'])
            : null);
    final optionValue =
        _stringFromJson(value['option_value'] ?? value['optionValue']) ??
        (option is Map
            ? _stringFromJson(option['value'] ?? option['optionValue'])
            : null);

    if (attributeName == null ||
        attributeName.isEmpty ||
        optionValue == null ||
        optionValue.isEmpty) {
      continue;
    }

    attributes[attributeName] = optionValue;
  }

  return attributes;
}

String? _stringFromJson(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
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

List<String> _stringList(Object? value) {
  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}

bool _familySafeFromJson(Map<String, dynamic> json, List<String> tags) {
  final explicitSafe = _boolFromJson(
    json['isFamilySafe'] ??
        json['familySafe'] ??
        json['safeForFamily'] ??
        json['isSafeForFamily'] ??
        json['family_friendly'],
  );
  if (explicitSafe != null) return explicitSafe;

  final explicitRestricted = _boolFromJson(
    json['isAgeRestricted'] ??
        json['ageRestricted'] ??
        json['age_restricted'] ??
        json['adult'] ??
        json['mature'] ??
        json['nsfw'],
  );
  if (explicitRestricted != null) return !explicitRestricted;

  return !tags.map((tag) => tag.trim().toLowerCase()).any(_isUnsafeTag);
}

bool? _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == 'no' || normalized == '0') {
      return false;
    }
  }
  return null;
}

bool _isUnsafeTag(String tag) {
  const unsafeTags = {
    '18+',
    'adult',
    'alcohol',
    'mature',
    'nsfw',
    'smoking',
    'tobacco',
    'vape',
    'weapon',
    'سجائر',
    'تدخين',
    'تبغ',
    'خمور',
    'كحول',
  };
  return unsafeTags.contains(tag);
}
