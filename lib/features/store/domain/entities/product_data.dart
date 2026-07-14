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

class ProductAttributeOptionData {
  const ProductAttributeOptionData({required this.id, required this.value});

  final String id;
  final String value;

  factory ProductAttributeOptionData.fromJson(Map<String, dynamic> json) {
    return ProductAttributeOptionData(
      id: json['id']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, Object?> toJson() => {'id': id, 'value': value};
}

class ProductAttributeData {
  const ProductAttributeData({
    required this.id,
    required this.name,
    this.options = const [],
  });

  final String id;
  final String name;
  final List<ProductAttributeOptionData> options;

  factory ProductAttributeData.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return ProductAttributeData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      options: rawOptions is List
          ? rawOptions
                .whereType<Map<String, dynamic>>()
                .map(ProductAttributeOptionData.fromJson)
                .where((option) => option.value.trim().isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }
}

class ProductAdditionData {
  const ProductAdditionData({
    required this.id,
    required this.name,
    required this.price,
    this.classification = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String price;
  final String classification;
  final bool isActive;

  factory ProductAdditionData.fromJson(Map<String, dynamic> json) {
    final classification = _mapFromJson(json['classification']);
    return ProductAdditionData(
      id: json['id']?.toString() ?? '',
      name:
          json['name_ar']?.toString() ??
          json['name']?.toString() ??
          json['name_en']?.toString() ??
          '',
      price: json['price']?.toString() ?? '',
      classification:
          json['classification_name']?.toString() ??
          classification?['name']?.toString() ??
          '',
      isActive: _boolFromJson(json['is_active'] ?? json['isActive']) ?? true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'classification': classification,
      'isActive': isActive,
    };
  }
}

class ProductData {
  const ProductData({
    required this.id,
    this.code,
    this.slug,
    required this.image,
    this.images = const [],
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
    this.attributes = const [],
    this.additions = const [],
    this.theme = 'other',
    this.isPopular = false,
    this.offerVariantId,
    this.offerQuantity = 1,
    this.applyProductDiscount = true,
  });

  final String id;
  final String? code;
  final String? slug;
  final String image;
  final List<String> images;
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
  final List<ProductAttributeData> attributes;
  final List<ProductAdditionData> additions;
  final String theme;
  final bool isPopular;
  final String? offerVariantId;
  final int offerQuantity;
  final bool applyProductDiscount;

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
    final variantPrices = parsedVariants
        .map((variant) => variant.price)
        .where((price) => price.trim().isNotEmpty)
        .toList(growable: false);
    final price =
        json['price']?.toString() ??
        (variantPrices.isEmpty ? '' : variantPrices.join(' ~ '));
    final images = _productImagesFromJson(json);

    return ProductData(
      id: json['id']?.toString() ?? '',
      code:
          json['code']?.toString() ??
          json['productCode']?.toString() ??
          json['product_code']?.toString(),
      slug: json['slug']?.toString(),
      image: images.first,
      images: images,
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? market?['name']?.toString() ?? '',
      price: price,
      oldPrice: json['oldPrice']?.toString() ?? json['old_price']?.toString(),
      discount: json['discount']?.toString() ?? '',
      tags: [...tags, if (market?['name'] != null) market!['name'].toString()],
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
      attributes: json['attributes'] is List
          ? (json['attributes'] as List)
                .whereType<Map<String, dynamic>>()
                .map(ProductAttributeData.fromJson)
                .where((attribute) => attribute.name.trim().isNotEmpty)
                .toList(growable: false)
          : const [],
      additions: _additionsFromJson(json['additions']),
      theme: json['theme']?.toString() ?? 'other',
      isPopular:
          _boolFromJson(json['isPopular'] ?? json['is_popular']) ?? false,
      offerVariantId:
          json['offerVariantId']?.toString() ??
          json['offer_variant_id']?.toString(),
      offerQuantity:
          (_intFromJson(json['offerQuantity'] ?? json['offer_quantity']) ?? 1)
              .clamp(1, 99)
              .toInt(),
      applyProductDiscount:
          _boolFromJson(
            json['applyProductDiscount'] ?? json['apply_product_discount'],
          ) ??
          true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'code': code,
      'slug': slug,
      'image': image,
      'images': images,
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
      'attributes': attributes.map((attribute) => attribute.toJson()).toList(),
      'additions': additions.map((addition) => addition.toJson()).toList(),
      'theme': theme,
      'isPopular': isPopular,
      'offerVariantId': offerVariantId,
      'offerQuantity': offerQuantity,
      'applyProductDiscount': applyProductDiscount,
    };
  }

  double get priceValue {
    final firstPrice = price.split(RegExp(r'[-~]')).first.trim();
    return double.tryParse(
          firstPrice.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', ''),
        ) ??
        0.0;
  }

  double get offerBasePriceValue {
    final selectedVariantId = offerVariantId?.trim();
    if (selectedVariantId != null && selectedVariantId.isNotEmpty) {
      for (final variant in variants) {
        if (variant.id == selectedVariantId) {
          return _moneyValue(variant.price);
        }
      }
    }
    return priceValue;
  }

  double get offerUnitPriceValue {
    if (!applyProductDiscount) return offerBasePriceValue;
    final percentage = _moneyValue(discount).clamp(0.0, 100.0).toDouble();
    return offerBasePriceValue * (1 - percentage / 100);
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

List<ProductAdditionData> _additionsFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) {
        if (item is Map<String, dynamic>) {
          return ProductAdditionData.fromJson(item);
        }
        if (item is Map) {
          return ProductAdditionData.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
        final id = item?.toString().trim() ?? '';
        if (id.isEmpty) return null;
        return ProductAdditionData(id: id, name: '#$id', price: '');
      })
      .whereType<ProductAdditionData>()
      .where((addition) => addition.isActive && addition.name.trim().isNotEmpty)
      .toList(growable: false);
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

List<String> _productImagesFromJson(Map<String, dynamic> json) {
  final candidates = <({bool isPrimary, int index, Object? value})>[];
  final rawImages = json['images'];
  if (rawImages is List) {
    for (var index = 0; index < rawImages.length; index++) {
      final item = rawImages[index];
      if (item is Map) {
        candidates.add((
          isPrimary:
              _boolFromJson(item['is_primary'] ?? item['isPrimary']) ?? false,
          index: index,
          value: item['url'] ?? item['image'],
        ));
      } else {
        candidates.add((isPrimary: false, index: index, value: item));
      }
    }
  }
  candidates.sort((left, right) {
    if (left.isPrimary == right.isPrimary) {
      return left.index.compareTo(right.index);
    }
    return left.isPrimary ? -1 : 1;
  });

  final images = <String>[];
  final seen = <String>{};
  void add(Object? value) {
    final resolved = _resolveImage(value, fallback: false);
    if (resolved.isEmpty || !seen.add(resolved)) return;
    images.add(resolved);
  }

  for (final candidate in candidates) {
    add(candidate.value);
  }
  add(json['image'] ?? json['imageUrl']);
  if (images.isEmpty) images.add(AppAssets.defaultProduct);
  return List.unmodifiable(images);
}

String _resolveImage(Object? value, {bool fallback = true}) {
  final image = value?.toString().trim() ?? '';
  if (image.isEmpty) return fallback ? AppAssets.defaultProduct : '';
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

int? _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double _moneyValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(
        value
                ?.toString()
                .replaceAll(RegExp(r'[^0-9.,-]'), '')
                .replaceAll(',', '') ??
            '',
      ) ??
      0;
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
