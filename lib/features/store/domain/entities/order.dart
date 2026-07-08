import '../../../cart/domain/entities/cart_item.dart';

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

enum OrderDeliveryType { fixedArea, delivery, manualQuote }

enum OrderDeliveryPriceStatus { fixed, pendingQuote }

class ShippingAddressData {
  const ShippingAddressData({
    this.id,
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
  });

  final String? id;
  final String fullName;
  final String phone;
  final String line1;
  final String city;
  final String state;
  final String country;
  final String postalCode;

  factory ShippingAddressData.fromJson(Map<String, dynamic> json) {
    return ShippingAddressData(
      id: json['id']?.toString(),
      fullName:
          json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      line1: json['line1']?.toString() ?? json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      postalCode:
          json['postalCode']?.toString() ??
          json['postal_code']?.toString() ??
          '',
    );
  }

  String get formatted {
    return [
      line1,
      city,
      state,
      country,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }

  Map<String, Object?> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'fullName': fullName,
      'phone': phone,
      'line1': line1,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }
}

class OrderItemData {
  const OrderItemData({
    required this.id,
    this.productId,
    this.variantId,
    required this.image,
    required this.brand,
    required this.title,
    required this.unitPrice,
    required this.quantity,
    this.attributes = const [],
  });

  factory OrderItemData.fromCartItem(CartItemData item) {
    return OrderItemData(
      id: item.id,
      productId: item.productId,
      variantId: item.variantId,
      image: item.image,
      brand: item.brand,
      title: item.title,
      unitPrice: item.price,
      quantity: item.quantity,
      attributes: item.attributes,
    );
  }

  final String id;
  final String? productId;
  final String? variantId;
  final String image;
  final String brand;
  final String title;
  final double unitPrice;
  final int quantity;
  final List<CartItemAttribute> attributes;

  factory OrderItemData.fromJson(Map<String, dynamic> json) {
    final variant = json['variant'] is Map<String, dynamic>
        ? json['variant'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final product = variant['product'] is Map<String, dynamic>
        ? variant['product'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return OrderItemData(
      id:
          (json['id'] ??
                  json['variant_id'] ??
                  variant['id'] ??
                  product['id'] ??
                  '')
              .toString(),
      productId:
          json['productId']?.toString() ??
          json['product_id']?.toString() ??
          product['id']?.toString(),
      variantId:
          json['variantId']?.toString() ??
          json['variant_id']?.toString() ??
          variant['id']?.toString(),
      image:
          json['image']?.toString() ??
          json['imageUrl']?.toString() ??
          product['image']?.toString() ??
          '',
      brand:
          json['brand']?.toString() ??
          product['category']?['name']?.toString() ??
          '',
      title:
          json['title']?.toString() ??
          json['name']?.toString() ??
          json['product_name']?.toString() ??
          product['name']?.toString() ??
          '',
      unitPrice: _doubleFromJson(
        json['unitPrice'] ??
            json['unit_price'] ??
            json['price'] ??
            variant['price'],
      ),
      quantity: _intFromJson(json['quantity']) ?? 1,
      attributes: _attributesFromJson(json['attributes']),
    );
  }

  double get lineTotal => unitPrice * quantity;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'productId': productId,
      'variantId': variantId,
      'image': image,
      'brand': brand,
      'title': title,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'attributes': attributes
          .map(
            (attribute) => {'label': attribute.label, 'value': attribute.value},
          )
          .toList(),
    };
  }
}

class OrderMarketSectionData {
  const OrderMarketSectionData({
    required this.marketId,
    required this.marketName,
    this.pickupStatus = '',
    this.subtotal = 0,
    this.items = const [],
    this.offers = const [],
  });

  final String marketId;
  final String marketName;
  final String pickupStatus;
  final double subtotal;
  final List<OrderItemData> items;
  final List<Map<String, dynamic>> offers;

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity) + offers.length;
  }

  factory OrderMarketSectionData.fromJson(Map<String, dynamic> json) {
    final market = _mapFromJson(json['market']);
    return OrderMarketSectionData(
      marketId:
          json['market_id']?.toString() ??
          market['id']?.toString() ??
          json['id']?.toString() ??
          '',
      marketName:
          json['market_name']?.toString() ??
          market['name']?.toString() ??
          json['name']?.toString() ??
          '',
      pickupStatus: json['pickup_status']?.toString() ?? '',
      subtotal: _doubleFromJson(json['subtotal'] ?? json['subtotal_price']),
      items: _itemsFromJson(json['items']),
      offers: _mapListFromJson(json['offers']),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'market_id': marketId,
      'market_name': marketName,
      'pickup_status': pickupStatus,
      'subtotal_price': subtotal,
      'items': items.map((item) => item.toJson()).toList(),
      'offers': offers,
    };
  }
}

class OrderData {
  const OrderData({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.placedAt,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    this.deliveryType = OrderDeliveryType.fixedArea,
    this.deliveryPriceStatus = OrderDeliveryPriceStatus.fixed,
    this.customDeliveryArea = '',
    this.deliveryLabel = '',
    this.reviewStatus = '',
    this.marketCount = 1,
    this.isMultiMarket = false,
    this.marketNamesSummary = '',
    this.marketSections = const [],
    this.offers = const [],
    required this.taxTotal,
    required this.discountTotal,
    required this.total,
    this.estimatedDeliveryAt,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final DateTime placedAt;
  final ShippingAddressData shippingAddress;
  final String paymentMethod;
  final List<OrderItemData> items;
  final double subtotal;
  final double shippingFee;
  final OrderDeliveryType deliveryType;
  final OrderDeliveryPriceStatus deliveryPriceStatus;
  final String customDeliveryArea;
  final String deliveryLabel;
  final String reviewStatus;
  final int marketCount;
  final bool isMultiMarket;
  final String marketNamesSummary;
  final List<OrderMarketSectionData> marketSections;
  final List<Map<String, dynamic>> offers;
  final double taxTotal;
  final double discountTotal;
  final double total;
  final DateTime? estimatedDeliveryAt;

  factory OrderData.fromJson(Map<String, dynamic> json) {
    final deliveryType = _deliveryTypeFromJson(json['delivery_type']);
    final rawDeliveryPrice =
        json['shippingFee'] ?? json['shipping_fee'] ?? json['delivery_price'];
    final marketSections = _marketSectionsFromJson(json['market_sections']);
    return OrderData(
      id: json['id'].toString(),
      orderNumber:
          json['orderNumber']?.toString() ??
          json['order_number']?.toString() ??
          json['orderCode']?.toString() ??
          json['order_code']?.toString() ??
          json['number']?.toString() ??
          json['code']?.toString() ??
          json['id']?.toString() ??
          '',
      status: _statusFromJson(json['status']),
      placedAt:
          _dateFromJson(
            json['placedAt'] ?? json['placed_at'] ?? json['created_at'],
          ) ??
          DateTime.now(),
      shippingAddress: ShippingAddressData.fromJson(
        _mapFromJson(
          json['shippingAddress'] ??
              json['shipping_address'] ??
              json['delivery_address'],
        ),
      ),
      paymentMethod:
          json['paymentMethod']?.toString() ??
          json['payment_method']?.toString() ??
          'cash',
      items: _itemsFromJson(json['items']),
      subtotal: _doubleFromJson(json['subtotal'] ?? json['subtotal_price']),
      shippingFee: _doubleFromJson(rawDeliveryPrice),
      deliveryType: deliveryType,
      deliveryPriceStatus: _deliveryPriceStatusFromJson(
        json['delivery_price_status'],
        deliveryType: deliveryType,
      ),
      customDeliveryArea: json['custom_delivery_area']?.toString() ?? '',
      deliveryLabel: json['delivery_label']?.toString() ?? '',
      reviewStatus: json['review_status']?.toString() ?? '',
      marketCount:
          _intFromJson(json['market_count']) ??
          (marketSections.isEmpty ? 1 : marketSections.length),
      isMultiMarket: _boolFromJson(json['is_multi_market']) ?? false,
      marketNamesSummary: json['market_names_summary']?.toString() ?? '',
      marketSections: marketSections,
      offers: _mapListFromJson(json['offers']),
      taxTotal: _doubleFromJson(json['taxTotal'] ?? json['tax_total']),
      discountTotal: _doubleFromJson(
        json['discountTotal'] ?? json['discount_total'] ?? json['discount'],
      ),
      total: _doubleFromJson(json['total'] ?? json['total_price']),
      estimatedDeliveryAt: _dateFromJson(
        json['estimatedDeliveryAt'] ?? json['estimated_delivery_at'],
      ),
    );
  }

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  String get statusLabel {
    return switch (status) {
      OrderStatus.pending => 'Pending',
      OrderStatus.processing => 'Preparing',
      OrderStatus.shipped => 'Ready',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };
  }

  String get reviewStatusLabel {
    final normalized = reviewStatus.trim().toLowerCase();
    return switch (normalized) {
      '' => '',
      'pending_review' || 'pending' => 'Pending review',
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      _ =>
        normalized
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' '),
    };
  }

  String get paymentMethodLabel {
    final normalized = paymentMethod.trim().toLowerCase();
    return switch (normalized) {
      'cash' || 'cash_on_delivery' => 'Cash on Delivery',
      _ => paymentMethod,
    };
  }

  String get deliveryTypeLabel {
    return switch (deliveryType) {
      OrderDeliveryType.fixedArea => 'Delivery',
      OrderDeliveryType.delivery || OrderDeliveryType.manualQuote => 'Courier',
    };
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'status': status.name,
      'placedAt': placedAt.toIso8601String(),
      'shippingAddress': shippingAddress.toJson(),
      'paymentMethod': paymentMethod,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'deliveryType': deliveryType.name,
      'deliveryPriceStatus': deliveryPriceStatus.name,
      'customDeliveryArea': customDeliveryArea,
      'deliveryLabel': deliveryLabel,
      'reviewStatus': reviewStatus,
      'marketCount': marketCount,
      'isMultiMarket': isMultiMarket,
      'marketNamesSummary': marketNamesSummary,
      'marketSections': marketSections
          .map((section) => section.toJson())
          .toList(),
      'offers': offers,
      'taxTotal': taxTotal,
      'discountTotal': discountTotal,
      'total': total,
      'estimatedDeliveryAt': estimatedDeliveryAt?.toIso8601String(),
    };
  }
}

OrderDeliveryType _deliveryTypeFromJson(Object? value) {
  final name = value?.toString().trim().toLowerCase();
  if (name == 'delivery') return OrderDeliveryType.delivery;
  if (name == 'manual_quote') return OrderDeliveryType.manualQuote;
  return OrderDeliveryType.fixedArea;
}

OrderDeliveryPriceStatus _deliveryPriceStatusFromJson(
  Object? value, {
  required OrderDeliveryType deliveryType,
}) {
  final name = value?.toString().trim().toLowerCase();
  if (name == 'pending_quote' || name == 'pending') {
    return OrderDeliveryPriceStatus.pendingQuote;
  }
  if (deliveryType == OrderDeliveryType.delivery ||
      deliveryType == OrderDeliveryType.manualQuote) {
    return OrderDeliveryPriceStatus.pendingQuote;
  }
  if (name == 'fixed') return OrderDeliveryPriceStatus.fixed;
  return OrderDeliveryPriceStatus.fixed;
}

OrderStatus _statusFromJson(Object? value) {
  final name = value?.toString().toLowerCase();
  if (name == 'confirmed' || name == 'under_preparation') {
    return OrderStatus.processing;
  }
  if (name == 'ready') return OrderStatus.shipped;
  return OrderStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => OrderStatus.processing,
  );
}

DateTime? _dateFromJson(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

List<OrderItemData> _itemsFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(OrderItemData.fromJson)
      .toList(growable: false);
}

List<OrderMarketSectionData> _marketSectionsFromJson(Object? value) {
  return _mapListFromJson(
    value,
  ).map(OrderMarketSectionData.fromJson).toList(growable: false);
}

List<Map<String, dynamic>> _mapListFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) => {
          for (final entry in item.entries)
            if (entry.key is String) entry.key as String: entry.value,
        },
      )
      .toList(growable: false);
}

Map<String, dynamic> _mapFromJson(Object? value) {
  if (value is Map<String, dynamic>) return value;
  return const {};
}

List<CartItemAttribute> _attributesFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(CartItemAttribute.fromJson)
      .toList(growable: false);
}

double _doubleFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int? _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return null;
}
