import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/api_endpoints.dart';
import 'category_data.dart';
import 'product_data.dart';

class StoreData {
  static const featuredSlotCount = 4;

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
  });

  final String id;
  final String name;
  final int marketCount;
  final List<ProductData> products;
  final String image;
  final int accentColorValue;
  final String classificationType;

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

class StoreMarketData {
  const StoreMarketData({
    required this.id,
    required this.name,
    required this.branch,
    required this.status,
    required this.classificationId,
    required this.products,
    required this.image,
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
  final String image;
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

    return StoreMarketData(
      id: id,
      name: name,
      branch: json['branch']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      classificationId: classificationId,
      products: products,
      image: _resolveImage(json['image']),
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
      image: image,
      accentColorValue: accentColorValue,
      isPopular: isPopular,
      createdAt: createdAt,
    );
  }

  String get productCountLabel {
    return '${products.length} product${products.length == 1 ? '' : 's'}';
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
