class OrderPreviewData {
  const OrderPreviewData({
    this.addresses = const [],
    this.selectedAddress,
    this.marketGroups = const [],
    required this.summary,
  });

  final List<Map<String, dynamic>> addresses;
  final Map<String, dynamic>? selectedAddress;
  final List<OrderPreviewMarketGroupData> marketGroups;
  final OrderPreviewSummaryData summary;

  bool get hasUnavailableDelivery {
    return marketGroups.any((group) => !group.deliveryAvailable);
  }

  factory OrderPreviewData.fromJson(Map<String, dynamic> json) {
    return OrderPreviewData(
      addresses: _mapListFromJson(json['addresses']),
      selectedAddress: _nullableMapFromJson(json['selected_address']),
      marketGroups: _mapListFromJson(
        json['market_groups'],
      ).map(OrderPreviewMarketGroupData.fromJson).toList(growable: false),
      summary: OrderPreviewSummaryData.fromJson(_mapFromJson(json['summary'])),
    );
  }
}

class OrderPreviewMarketGroupData {
  const OrderPreviewMarketGroupData({
    this.market = const {},
    this.deliveryArea = const {},
    required this.deliveryAvailable,
    required this.pricing,
  });

  final Map<String, dynamic> market;
  final Map<String, dynamic> deliveryArea;
  final bool deliveryAvailable;
  final OrderPreviewPricingData pricing;

  factory OrderPreviewMarketGroupData.fromJson(Map<String, dynamic> json) {
    return OrderPreviewMarketGroupData(
      market: _mapFromJson(json['market']),
      deliveryArea: _mapFromJson(json['delivery_area']),
      deliveryAvailable: json['delivery_available'] == true,
      pricing: OrderPreviewPricingData.fromJson(_mapFromJson(json['pricing'])),
    );
  }
}

class OrderPreviewPricingData {
  const OrderPreviewPricingData({
    required this.productsSubtotal,
    required this.totalOfferDiscounts,
    required this.deliveryPrice,
    required this.marketTotal,
  });

  final double productsSubtotal;
  final double totalOfferDiscounts;
  final double deliveryPrice;
  final double marketTotal;

  factory OrderPreviewPricingData.fromJson(Map<String, dynamic> json) {
    return OrderPreviewPricingData(
      productsSubtotal: _doubleFromJson(json['products_subtotal']),
      totalOfferDiscounts: _doubleFromJson(json['total_offer_discounts']),
      deliveryPrice: _doubleFromJson(json['delivery_price']),
      marketTotal: _doubleFromJson(json['market_total']),
    );
  }
}

class OrderPreviewSummaryData {
  const OrderPreviewSummaryData({
    required this.subtotal,
    required this.discountTotal,
    required this.deliveryTotal,
    required this.grandTotal,
  });

  final double subtotal;
  final double discountTotal;
  final double deliveryTotal;
  final double grandTotal;

  factory OrderPreviewSummaryData.fromJson(Map<String, dynamic> json) {
    return OrderPreviewSummaryData(
      subtotal: _doubleFromJson(json['subtotal']),
      discountTotal: _doubleFromJson(json['discount_total']),
      deliveryTotal: _doubleFromJson(json['delivery_total']),
      grandTotal: _doubleFromJson(json['grand_total']),
    );
  }
}

List<Map<String, dynamic>> _mapListFromJson(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

Map<String, dynamic>? _nullableMapFromJson(Object? value) {
  if (value is Map<String, dynamic>) return value;
  return null;
}

Map<String, dynamic> _mapFromJson(Object? value) {
  if (value is Map<String, dynamic>) return value;
  return const {};
}

double _doubleFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
