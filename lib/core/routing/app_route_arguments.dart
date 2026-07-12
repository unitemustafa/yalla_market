class NavigationMenuRouteArgs {
  const NavigationMenuRouteArgs({this.initialIndex = 0, this.focusOfferId});

  final int initialIndex;
  final String? focusOfferId;
}

class OrderFocusRouteArgs {
  const OrderFocusRouteArgs({required this.orderId});

  final int orderId;
}

class AllProductsRouteArgs {
  const AllProductsRouteArgs({
    this.title = 'Popular Products',
    this.subtitle = 'Browse all curated products',
  });

  final String title;
  final String subtitle;
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
  });

  final String image;
  final String title;
  final String brand;
  final String price;
  final String productId;
  final String? productSlug;
  final String? oldPrice;
  final String? discount;
}
