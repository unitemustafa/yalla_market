class OrderPreviewData {
  const OrderPreviewData({
    this.addresses = const [],
    this.selectedAddress,
    this.serviceCity,
    this.orderScope = '',
    this.fulfillmentType = '',
    this.externalShippingStatus = '',
    this.etaMinMinutes,
    this.etaMaxMinutes,
    this.isMultiMarket = false,
    this.marketCount = 0,
    this.marketNamesSummary = '',
    this.marketGroups = const [],
    required this.summary,
  });

  final List<Map<String, dynamic>> addresses;
  final Map<String, dynamic>? selectedAddress;
  final Map<String, dynamic>? serviceCity;
  final String orderScope;
  final String fulfillmentType;
  final String externalShippingStatus;
  final int? etaMinMinutes;
  final int? etaMaxMinutes;
  final bool isMultiMarket;
  final int marketCount;
  final String marketNamesSummary;
  final List<OrderPreviewMarketGroupData> marketGroups;
  final OrderPreviewSummaryData summary;

  bool get hasPendingDeliveryQuote {
    return marketGroups.any((group) => group.isPendingDeliveryQuote);
  }

  bool get hasUnavailableDelivery {
    return marketGroups.any((group) => !group.deliveryAvailable);
  }

  factory OrderPreviewData.fromJson(Map<String, dynamic> json) {
    return OrderPreviewData(
      addresses: _mapListFromJson(json['addresses']),
      selectedAddress: _nullableMapFromJson(json['selected_address']),
      serviceCity: _nullableMapFromJson(json['service_city']),
      orderScope: json['order_scope']?.toString() ?? '',
      fulfillmentType: json['fulfillment_type']?.toString() ?? '',
      externalShippingStatus:
          json['external_shipping_status']?.toString() ?? '',
      etaMinMinutes: _intFromJson(json['eta_min_minutes']),
      etaMaxMinutes: _intFromJson(json['eta_max_minutes']),
      isMultiMarket: _boolFromJson(json['is_multi_market']) ?? false,
      marketCount:
          _intFromJson(json['market_count']) ??
          _mapListFromJson(json['market_groups']).length,
      marketNamesSummary: json['market_names_summary']?.toString() ?? '',
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
    this.serviceCity = const {},
    this.deliveryArea = const {},
    this.deliveryType = '',
    this.fulfillmentType = '',
    this.externalShippingStatus = '',
    this.etaMinMinutes,
    this.etaMaxMinutes,
    this.deliveryPrice,
    this.deliveryMessage = '',
    required this.deliveryAvailable,
    this.selectedProducts = const [],
    this.selectedOffers = const [],
    required this.pricing,
  });

  final Map<String, dynamic> market;
  final Map<String, dynamic> serviceCity;
  final Map<String, dynamic> deliveryArea;
  final String deliveryType;
  final String fulfillmentType;
  final String externalShippingStatus;
  final int? etaMinMinutes;
  final int? etaMaxMinutes;
  final double? deliveryPrice;
  final String deliveryMessage;
  final bool deliveryAvailable;
  final List<Map<String, dynamic>> selectedProducts;
  final List<Map<String, dynamic>> selectedOffers;
  final OrderPreviewPricingData pricing;

  bool get isFixedAreaDelivery => deliveryType == 'fixed_area';

  bool get isPendingDeliveryQuote {
    if (externalShippingStatus.isNotEmpty) {
      return externalShippingStatus == 'pending_quote';
    }
    if (fulfillmentType.isNotEmpty) {
      return fulfillmentType == 'external_shipping';
    }
    return deliveryType == 'delivery' || deliveryType == 'manual_quote';
  }

  String get marketName {
    return market['name']?.toString() ?? '';
  }

  factory OrderPreviewMarketGroupData.fromJson(Map<String, dynamic> json) {
    return OrderPreviewMarketGroupData(
      market: _mapFromJson(json['market']),
      serviceCity: _mapFromJson(json['service_city']),
      deliveryArea: _mapFromJson(json['delivery_area']),
      deliveryType:
          json['delivery_type']?.toString().trim().toLowerCase() ?? '',
      fulfillmentType:
          json['fulfillment_type']?.toString().trim().toLowerCase() ?? '',
      externalShippingStatus:
          json['external_shipping_status']?.toString().trim().toLowerCase() ??
          '',
      etaMinMinutes: _intFromJson(json['eta_min_minutes']),
      etaMaxMinutes: _intFromJson(json['eta_max_minutes']),
      deliveryPrice: _nullableDoubleFromJson(json['delivery_price']),
      deliveryMessage: json['delivery_message']?.toString() ?? '',
      deliveryAvailable: _boolFromJson(json['delivery_available']) ?? false,
      selectedProducts: _mapListFromJson(json['selected_products']),
      selectedOffers: _mapListFromJson(json['selected_offers']),
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
  final double? deliveryPrice;
  final double marketTotal;

  factory OrderPreviewPricingData.fromJson(Map<String, dynamic> json) {
    return OrderPreviewPricingData(
      productsSubtotal: _doubleFromJson(json['products_subtotal']),
      totalOfferDiscounts: _doubleFromJson(json['total_offer_discounts']),
      deliveryPrice: _nullableDoubleFromJson(json['delivery_price']),
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
  return value
      .whereType<Map>()
      .map(_stringKeyMapFromJson)
      .toList(growable: false);
}

Map<String, dynamic>? _nullableMapFromJson(Object? value) {
  if (value is Map) return _stringKeyMapFromJson(value);
  return null;
}

Map<String, dynamic> _mapFromJson(Object? value) {
  if (value is Map) return _stringKeyMapFromJson(value);
  return const {};
}

Map<String, dynamic> _stringKeyMapFromJson(Map value) {
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

bool? _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is String) return bool.tryParse(value.toLowerCase());
  return null;
}

double _doubleFromJson(Object? value) {
  return _nullableDoubleFromJson(value) ?? 0;
}

double? _nullableDoubleFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
