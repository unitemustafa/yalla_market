import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/api_endpoints.dart';
import 'product_data.dart';

class StoreData {
  const StoreData({
    required this.commonClassifications,
    required this.classifications,
    required this.marketsByClassificationId,
  });

  final List<StoreClassificationData> commonClassifications;
  final List<StoreClassificationData> classifications;
  final Map<String, List<StoreMarketData>> marketsByClassificationId;

  StoreData copyWith({
    List<StoreClassificationData>? commonClassifications,
    List<StoreClassificationData>? classifications,
    Map<String, List<StoreMarketData>>? marketsByClassificationId,
  }) {
    return StoreData(
      commonClassifications:
          commonClassifications ?? this.commonClassifications,
      classifications: classifications ?? this.classifications,
      marketsByClassificationId:
          marketsByClassificationId ?? this.marketsByClassificationId,
    );
  }

  List<StoreMarketData> marketsFor(String classificationId) {
    return marketsByClassificationId[classificationId] ?? const [];
  }
}

class StoreClassificationData {
  const StoreClassificationData({
    required this.id,
    required this.name,
    required this.productCount,
    required this.products,
    required this.image,
    required this.accentColorValue,
  });

  final String id;
  final String name;
  final int productCount;
  final List<ProductData> products;
  final String image;
  final int accentColorValue;

  factory StoreClassificationData.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final products = _jsonList(
      json['products'],
    ).map(ProductData.fromJson).toList(growable: false);

    return StoreClassificationData(
      id: id,
      name: name,
      productCount: _intFromJson(json['product_count']) ?? products.length,
      products: products,
      image: _resolveImage(json['image']),
      accentColorValue: _accentColorFor(id.isEmpty ? name : id),
    );
  }

  String get productCountLabel {
    return '$productCount product${productCount == 1 ? '' : 's'}';
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
  });

  final String id;
  final String name;
  final String branch;
  final String status;
  final String classificationId;
  final List<ProductData> products;
  final String image;
  final int accentColorValue;

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
      image: products.isEmpty
          ? AppAssets.temporaryMarketPlaceholder
          : products.first.image,
      accentColorValue: _accentColorFor(id.isEmpty ? name : id),
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
      image: products.isEmpty ? image : products.first.image,
      accentColorValue: accentColorValue,
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
  const colors = [0xFF4F60F6, 0xFF22C55E, 0xFFF59E0B, 0xFFEF4444];
  final index = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return colors[index % colors.length];
}
