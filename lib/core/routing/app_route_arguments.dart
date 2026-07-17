import '../../features/store/domain/entities/category_data.dart';

class NavigationMenuRouteArgs {
  const NavigationMenuRouteArgs({this.initialIndex = 0, this.focusOfferId});

  final int initialIndex;
  final String? focusOfferId;
}

class OrderFocusRouteArgs {
  const OrderFocusRouteArgs({required this.orderId});

  final int orderId;
}

enum ProductCollectionType { popular, latest }

class AllProductsRouteArgs {
  const AllProductsRouteArgs({
    this.title = 'Popular Products',
    this.subtitle = 'Browse all curated products',
    this.collection = ProductCollectionType.popular,
    this.maxItems,
  });

  final String title;
  final String subtitle;
  final ProductCollectionType collection;
  final int? maxItems;
}

class CategoriesRouteArgs {
  const CategoriesRouteArgs({required this.categories});

  final List<CategoryData> categories;
}

class AddressesRouteArgs {
  const AddressesRouteArgs({this.returnAfterSelection = false});

  final bool returnAfterSelection;
}

class SelectCityRouteArgs {
  const SelectCityRouteArgs({this.returnToCheckout = false});

  final bool returnToCheckout;
}

class PaymentSuccessRouteArgs {
  const PaymentSuccessRouteArgs({
    required this.orderId,
    required this.status,
    required this.reviewStatus,
    required this.total,
    required this.marketCount,
    required this.marketSummary,
    required this.isMultiMarket,
    required this.marketSections,
  });

  final String orderId;
  final String status;
  final String reviewStatus;
  final String total;
  final int marketCount;
  final String marketSummary;
  final bool isMultiMarket;
  final List<Map<String, Object?>> marketSections;
}

class BrandProductsRouteArgs {
  const BrandProductsRouteArgs({
    required this.brand,
    required this.logo,
    required this.productCount,
    this.shopId,
    this.classificationId,
    this.marketId,
  });

  final String brand;
  final String logo;
  final String productCount;
  final String? shopId;
  final String? classificationId;
  final String? marketId;
}

class ProductDetailRouteArgs {
  const ProductDetailRouteArgs({
    required this.image,
    required this.title,
    required this.brand,
    required this.price,
    required this.productId,
    this.productSlug,
    this.oldPrice,
    this.discount,
    this.initialVariantId,
  });

  factory ProductDetailRouteArgs.fromNotificationData(
    Map<String, dynamic> data, {
    required String productId,
  }) {
    final discountValue = _routeText(data['discount']);
    final discountNumber = double.tryParse(discountValue);
    final discount = discountNumber != null && discountNumber > 0
        ? '${_trimRouteDecimal(discountNumber)}%'
        : null;

    return ProductDetailRouteArgs(
      productId: productId,
      image: _routeText(data['image']),
      title: _routeText(data['product_name']),
      brand: _routeText(data['market_name']),
      price: _routeText(data['price_text']).isNotEmpty
          ? _routeText(data['price_text'])
          : _routeText(data['price']),
      discount: discount,
    );
  }

  final String image;
  final String title;
  final String brand;
  final String price;
  final String productId;
  final String? productSlug;
  final String? oldPrice;
  final String? discount;
  final String? initialVariantId;
}

String _routeText(Object? value) => value?.toString().trim() ?? '';

String _trimRouteDecimal(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
