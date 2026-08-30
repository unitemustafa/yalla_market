import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/api_endpoints.dart';
import 'category_data.dart';
import 'product_data.dart';

class StoreData {
  static const featuredSlotCount = 8;

  const StoreData({
    required this.commonClassifications,
    required this.classifications,
    required this.marketsByClassificationId,
    this.latestMarkets = const [],
  });

  final List<StoreClassificationData> commonClassifications;
  final List<StoreClassificationData> classifications;
  final Map<String, List<StoreMarketData>> marketsByClassificationId;
  final List<StoreMarketData> latestMarkets;

  StoreData copyWith({
    List<StoreClassificationData>? commonClassifications,
    List<StoreClassificationData>? classifications,
    Map<String, List<StoreMarketData>>? marketsByClassificationId,
    List<StoreMarketData>? latestMarkets,
  }) {
    return StoreData(
      commonClassifications:
          commonClassifications ?? this.commonClassifications,
      classifications: classifications ?? this.classifications,
      marketsByClassificationId:
          marketsByClassificationId ?? this.marketsByClassificationId,
      latestMarkets: latestMarkets ?? this.latestMarkets,
    );
  }

  List<StoreMarketData> marketsFor(String classificationId) {
    final markets = marketsByClassificationId[classificationId] ?? const [];
    return List<StoreMarketData>.unmodifiable(markets);
  }

  List<StoreMarketData> popularMarketsFor(String classificationId) {
    return marketsFor(
      classificationId,
    ).where((market) => market.isPopular).toList(growable: false);
  }

  List<StoreClassificationData> get featuredCandidates => [
    ...classifications.where(
      (classification) => classification.classificationType == 'featured',
    ),
    ...classifications.where(
      (classification) => classification.classificationType == 'normal',
    ),
  ];

  List<StoreClassificationData> get featuredSlots =>
      featuredCandidates.take(featuredSlotCount).toList(growable: false);

  bool get hasFeaturedOverflow => featuredCandidates.length > featuredSlotCount;
}

class StoreClassificationData {
  const StoreClassificationData({
    required this.id,
    required this.name,
    required this.marketCount,
    required this.products,
    required this.image,
    required this.accentColorValue,
    required this.classificationType,
    this.marketTypes = const [],
  });

  final String id;
  final String name;
  final int marketCount;
  final List<ProductData> products;
  final String image;
  final int accentColorValue;
  final String classificationType;
  final List<StoreMarketTypeData> marketTypes;

  factory StoreClassificationData.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final products = _jsonList(
      json['products'],
    ).map(ProductData.fromJson).toList(growable: false);

    return StoreClassificationData(
      id: id,
      name: name,
      marketCount:
          _intFromJson(json['market_count']) ??
          _jsonList(json['markets']).length,
      products: products,
      image: _resolveImage(json['image']),
      accentColorValue: _accentColorFor(id.isEmpty ? name : id),
      classificationType: json['classification_type']?.toString() ?? 'normal',
      marketTypes: _jsonList(json['market_types'])
          .map(StoreMarketTypeData.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false),
    );
  }

  String get marketCountLabel {
    return '$marketCount store${marketCount == 1 ? '' : 's'}';
  }

  CategoryData toCategoryData() {
    return CategoryData(
      id: id,
      name: name,
      slug: id,
      productCount: products.length,
      image: image,
      galleryImages: const [],
      accentColorValue: accentColorValue,
      marketCount: marketCount,
      classificationType: classificationType,
    );
  }
}

class StoreMarketTypeData {
  const StoreMarketTypeData({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.image,
    required this.sortOrder,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String image;
  final int sortOrder;

  factory StoreMarketTypeData.fromJson(Map<String, dynamic> json) {
    return StoreMarketTypeData(
      id: json['id']?.toString() ?? '',
      nameAr: json['name_ar']?.toString().trim() ?? '',
      nameEn: json['name_en']?.toString().trim() ?? '',
      image: _resolveImage(json['image']),
      sortOrder: _intFromJson(json['sort_order']) ?? 0,
    );
  }

  String localizedName(String _) {
    if (nameAr.isNotEmpty) return nameAr;
    return nameEn.isNotEmpty ? nameEn : nameAr;
  }
}

class StoreMarketData {
  const StoreMarketData({
    required this.id,
    required this.name,
    required this.branch,
    required this.status,
    required this.classificationId,
    required this.products,
    this.subcategories = const [],
    this.marketTypeIds = const [],
    required this.image,
    this.coverImage = AppAssets.temporaryMarketPlaceholder,
    this.description = '',
    this.deliveryTimeMinMinutes,
    this.deliveryTimeMaxMinutes,
    this.productCount = -1,
    this.minimumProductPrice,
    this.isLiked = false,
    required this.accentColorValue,
    this.isPopular = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String branch;
  final String status;
  final String classificationId;
  final List<ProductData> products;
  final List<StoreSubcategoryData> subcategories;
  final List<String> marketTypeIds;
  final String image;
  final String coverImage;
  final String description;
  final int? deliveryTimeMinMinutes;
  final int? deliveryTimeMaxMinutes;
  final int productCount;
  final double? minimumProductPrice;
  final bool isLiked;
  final int accentColorValue;
  final bool isPopular;
  final DateTime? createdAt;

  factory StoreMarketData.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final classificationId = json['classification_id']?.toString() ?? '';
    final products = _jsonList(json['products'])
        .map((product) => _productFromMarketJson(product, json))
        .map(ProductData.fromJson)
        .toList(growable: false);
    final subcategories =
        _jsonList(json['subcategories'])
            .map(StoreSubcategoryData.fromJson)
            .where((item) => item.id.isNotEmpty && item.isActive)
            .toList(growable: false)
          ..sort((first, second) {
            final order = first.sortOrder.compareTo(second.sortOrder);
            return order != 0 ? order : first.id.compareTo(second.id);
          });
    final marketTypeIds = json['market_type_ids'] is List
        ? (json['market_type_ids'] as List)
              .map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList(growable: false)
        : const <String>[];

    return StoreMarketData(
      id: id,
      name: name,
      branch: json['branch']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      classificationId: classificationId,
      products: products,
      subcategories: List.unmodifiable(subcategories),
      marketTypeIds: List.unmodifiable(marketTypeIds),
      image: _resolveImage(json['image']),
      coverImage: _resolveImage(json['cover_image']),
      description: json['description']?.toString().trim() ?? '',
      deliveryTimeMinMinutes: _intFromJson(json['delivery_time_min_minutes']),
      deliveryTimeMaxMinutes: _intFromJson(json['delivery_time_max_minutes']),
      productCount: _intFromJson(json['product_count']) ?? products.length,
      minimumProductPrice: double.tryParse(
        json['minimum_product_price']?.toString() ?? '',
      ),
      isLiked: json['is_liked'] == true,
      accentColorValue: _accentColorFor(id.isEmpty ? name : id),
      isPopular: json['is_popular'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  StoreMarketData copyWithProducts(List<ProductData> products) {
    return StoreMarketData(
      id: id,
      name: name,
      branch: branch,
      status: status,
      classificationId: classificationId,
      products: products,
      subcategories: subcategories,
      marketTypeIds: marketTypeIds,
      image: image,
      coverImage: coverImage,
      description: description,
      deliveryTimeMinMinutes: deliveryTimeMinMinutes,
      deliveryTimeMaxMinutes: deliveryTimeMaxMinutes,
      productCount: productCount,
      minimumProductPrice: minimumProductPrice,
      isLiked: isLiked,
      accentColorValue: accentColorValue,
      isPopular: isPopular,
      createdAt: createdAt,
    );
  }

  String get productCountLabel {
    final count = effectiveProductCount;
    return '$count product${count == 1 ? '' : 's'}';
  }

  int get effectiveProductCount =>
      productCount >= 0 ? productCount : products.length;

  StoreMarketData copyWithFavorite(bool value) {
    return StoreMarketData(
      id: id,
      name: name,
      branch: branch,
      status: status,
      classificationId: classificationId,
      products: products,
      subcategories: subcategories,
      marketTypeIds: marketTypeIds,
      image: image,
      coverImage: coverImage,
      description: description,
      deliveryTimeMinMinutes: deliveryTimeMinMinutes,
      deliveryTimeMaxMinutes: deliveryTimeMaxMinutes,
      productCount: productCount,
      minimumProductPrice: minimumProductPrice,
      isLiked: value,
      accentColorValue: accentColorValue,
      isPopular: isPopular,
      createdAt: createdAt,
    );
  }

  String get deliveryTimeLabel {
    final minimum = deliveryTimeMinMinutes;
    final maximum = deliveryTimeMaxMinutes;
    if (minimum == null || maximum == null) return '';
    return minimum == maximum ? '$minimum min' : '$minimum-$maximum min';
  }
}

Map<String, dynamic> _productFromMarketJson(
  Map<String, dynamic> product,
  Map<String, dynamic> market,
) {
  return {
    ...product,
    'market': {
      'id': market['id'],
      'name': market['name'],
      'classification_id': market['classification_id'],
    },
  };
}

List<Map<String, dynamic>> _jsonList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
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

int? _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
  }
  return null;
}

int _accentColorFor(String seed) {
  const colors = [0xFF013C7E, 0xFF22C55E, 0xFFF59E0B, 0xFFEF4444];
  final index = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return colors[index % colors.length];
}
