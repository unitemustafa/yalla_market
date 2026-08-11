import 'product_data.dart';

class MarketShopData {
  const MarketShopData({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.citySlug,
    required this.cityName,
    required this.logo,
    required this.galleryImages,
    required this.accentColorValue,
    required this.rating,
    required this.deliveryEstimate,
    required this.products,
  });

  final String id;
  final String name;
  final String categoryName;
  final String citySlug;
  final String cityName;
  final String logo;
  final List<String> galleryImages;
  final int accentColorValue;
  final double rating;
  final String deliveryEstimate;
  final List<ProductData> products;

  int get productCount => products.length;

  String get productCountLabel => '$productCount منتج';
}
