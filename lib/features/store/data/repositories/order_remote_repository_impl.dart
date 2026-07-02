import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_preview.dart';
import '../../domain/repositories/order_repository.dart';

class OrderRemoteRepositoryImpl implements OrderRepository {
  OrderRemoteRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<OrderData>> createOrder({
    required ShippingAddressData shippingAddress,
    required List<OrderItemData> items,
    List<CartItemData> cartItems = const [],
    String? paymentMethod,
    String? deliveryType,
    String? customDeliveryArea,
    String? deliveryAreaId,
    String? description,
    String? deliveryNote,
    double shippingFee = 0,
    double taxTotal = 0,
    double discountTotal = 0,
  }) {
    final invalidProductItem = cartItems.isNotEmpty
        ? cartItems
              .where((item) => !item.isOffer)
              .any((item) => item.variantId?.trim().isEmpty ?? true)
        : items.any((item) => item.variantId?.trim().isEmpty ?? true);
    if (invalidProductItem) {
      return Future.value(
        const ApiResult.failure(
          ValidationFailure(
            'Some cart items are missing variant information. Please add them again.',
          ),
        ),
      );
    }

    final invalidOfferFailure = _validateOfferIds(cartItems);
    if (invalidOfferFailure != null) {
      return Future.value(ApiResult.failure(invalidOfferFailure));
    }

    return _guard(() async {
      final payload = await _apiClient.post<Object?>(
        '/orders/create/',
        data: _createOrderPayload(
          cartItems: cartItems,
          orderItems: items,
          description: description,
          deliveryNote: deliveryNote,
        ),
      );
      return _orderFromCreatePayload(payload);
    }, fallbackMessage: 'Could not create order');
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() {
    return _guard(() async {
      final payload = await _apiClient.get<Object?>('/orders/my/');
      return _ordersFromPayload(payload);
    });
  }

  @override
  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
  }) {
    final invalidProductItem = cartItems.any(
      (item) => !item.isOffer && (item.variantId?.trim().isEmpty ?? true),
    );
    if (invalidProductItem) {
      return Future.value(
        const ApiResult.failure(
          ValidationFailure(
            'Some cart items are missing variant information. Please add them again.',
          ),
        ),
      );
    }

    final invalidOfferFailure = _validateOfferIds(cartItems);
    if (invalidOfferFailure != null) {
      return Future.value(ApiResult.failure(invalidOfferFailure));
    }

    return _guard(() async {
      final payload = await _apiClient.post<Map<String, dynamic>>(
        '/orders/preview/',
        data: {
          'items': cartItems
              .where((item) => !item.isOffer)
              .map(
                (item) => {
                  'variant_id': _idFromString(item.variantId),
                  'quantity': item.quantity,
                },
              )
              .toList(growable: false),
          'offers': cartItems
              .where((item) => item.isOffer)
              .map((item) => {'offer_id': _offerIdFromCartItem(item)!})
              .toList(growable: false),
        },
      );
      return OrderPreviewData.fromJson(payload);
    });
  }

  List<OrderData> _ordersFromPayload(Object? payload) {
    final rawItems = payload is Map<String, dynamic>
        ? payload['results'] ?? payload['items'] ?? payload['orders']
        : payload;
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(OrderData.fromJson)
        .toList(growable: false);
  }

  OrderData _orderFromCreatePayload(Object? payload) {
    final order = _orderMapFromCreatePayload(payload);
    if (order != null) return OrderData.fromJson(order);

    throw const FormatException('Create order response did not contain order.');
  }

  Map<String, dynamic>? _orderMapFromCreatePayload(Object? payload) {
    final directOrder = _mapFromPayload(payload);
    if (directOrder != null) return directOrder;

    if (payload is List) {
      for (final item in payload) {
        final order = _orderMapFromCreatePayload(item);
        if (order != null) return order;
      }
    }

    if (payload is Map) {
      for (final key in const ['order', 'data', 'result']) {
        final order = _orderMapFromCreatePayload(payload[key]);
        if (order != null) return order;
      }
    }

    return null;
  }

  Map<String, dynamic>? _mapFromPayload(Object? payload) {
    if (payload is! Map) return null;
    final map = Map<String, dynamic>.from(payload);
    return map.containsKey('id') ? map : null;
  }

  Future<ApiResult<T>> _guard<T>(
    Future<T> Function() action, {
    String fallbackMessage = 'Could not load orders.',
  }) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return ApiResult.failure(UnknownFailure(fallbackMessage));
    }
  }

  Map<String, Object?> _createOrderPayload({
    required List<CartItemData> cartItems,
    required List<OrderItemData> orderItems,
    String? description,
    String? deliveryNote,
  }) {
    final hasCartItems = cartItems.isNotEmpty;
    return {
      'payment_method': 'cash_on_delivery',
      'description': description?.trim() ?? '',
      'delivery_note': deliveryNote?.trim() ?? '',
      'items': hasCartItems
          ? cartItems
                .where((item) => !item.isOffer)
                .map(
                  (item) => {
                    'variant_id': _idFromString(item.variantId),
                    'quantity': item.quantity,
                  },
                )
                .toList(growable: false)
          : orderItems
                .map(
                  (item) => {
                    'variant_id': _idFromString(item.variantId),
                    'quantity': item.quantity,
                  },
                )
                .toList(growable: false),
      'offers': cartItems
          .where((item) => item.isOffer)
          .map((item) => {'offer_id': _offerIdFromCartItem(item)!})
          .toList(growable: false),
    };
  }

  ValidationFailure? _validateOfferIds(List<CartItemData> cartItems) {
    for (final item in cartItems.where((item) => item.isOffer)) {
      if (_offerIdFromCartItem(item) == null) {
        return const ValidationFailure(
          'Some offer items are missing valid offer information. Please add them again.',
        );
      }
    }
    return null;
  }
}

int? _offerIdFromCartItem(CartItemData item) {
  return _offerIdFromValue(item.productId) ?? _offerIdFromValue(item.id);
}

Object? _idFromString(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return int.tryParse(trimmed) ?? trimmed;
}

int? _offerIdFromValue(Object? value) {
  if (value is int) return value > 0 ? value : null;
  if (value is num) {
    final id = value.toInt();
    return value == id && id > 0 ? id : null;
  }

  final trimmed = value?.toString().trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final directId = int.tryParse(trimmed);
  if (directId != null) return directId > 0 ? directId : null;

  final clearOfferId = RegExp(
    r'^offer[_-](\d+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (clearOfferId == null) return null;

  final parsedId = int.tryParse(clearOfferId.group(1)!);
  return parsedId != null && parsedId > 0 ? parsedId : null;
}
