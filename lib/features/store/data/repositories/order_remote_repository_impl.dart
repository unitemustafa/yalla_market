import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/checkout_error_messages.dart';
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
  Future<ApiResult<List<OrderData>>> createOrder({
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
    final payloadResult = _checkoutPayload(
      cartItems: cartItems,
      orderItems: items,
      addressId: shippingAddress.id,
      paymentMethod: paymentMethod,
      description: description,
      deliveryNote: deliveryNote,
    );
    if (payloadResult.failure case final failure?) {
      return Future.value(ApiResult.failure(failure));
    }

    return _guard(
      () async {
        final payload = await _apiClient.post<Object?>(
          '/orders/create/',
          data: payloadResult.payload,
        );
        final orders = _ordersFromCreatePayload(payload);
        if (orders.isEmpty) {
          throw const FormatException(
            'Create order response did not contain orders.',
          );
        }
        return orders;
      },
      fallbackMessage: 'Could not create order',
      errorMapper: _checkoutError,
    );
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
    required String addressId,
    String? paymentMethod,
    String? description,
    String? deliveryNote,
  }) {
    final payloadResult = _checkoutPayload(
      cartItems: cartItems,
      orderItems: const [],
      addressId: addressId,
      paymentMethod: paymentMethod,
      description: description,
      deliveryNote: deliveryNote,
    );
    if (payloadResult.failure case final failure?) {
      return Future.value(ApiResult.failure(failure));
    }

    return _guard(() async {
      final payload = await _apiClient.post<Map<String, dynamic>>(
        '/orders/preview/',
        data: payloadResult.payload,
      );
      return OrderPreviewData.fromJson(payload);
    }, errorMapper: _checkoutError);
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

  List<OrderData> _ordersFromCreatePayload(Object? payload) {
    final rawOrders = _orderListFromCreatePayload(payload);
    return rawOrders.map(OrderData.fromJson).toList(growable: false);
  }

  List<Map<String, dynamic>> _orderListFromCreatePayload(Object? payload) {
    if (payload is List) {
      final first = payload.firstOrNull;
      if (first is! Map || !first.containsKey('id')) return const [];
      return [Map<String, dynamic>.from(first)];
    }

    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      if (map.containsKey('id')) return [map];

      for (final key in const [
        'order',
        'orders',
        'results',
        'items',
        'data',
        'result',
      ]) {
        final orders = _orderListFromCreatePayload(payload[key]);
        if (orders.isNotEmpty) return orders;
      }
    }

    return const [];
  }

  Future<ApiResult<T>> _guard<T>(
    Future<T> Function() action, {
    String fallbackMessage = 'Could not load orders.',
    Failure Function(DioException error)? errorMapper,
  }) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(
        errorMapper?.call(error) ?? ApiErrorHandler.handle(error),
      );
    } catch (_) {
      return ApiResult.failure(UnknownFailure(fallbackMessage));
    }
  }

  ({Map<String, Object?> payload, ValidationFailure? failure})
  _checkoutPayload({
    required List<CartItemData> cartItems,
    required List<OrderItemData> orderItems,
    required String? addressId,
    String? paymentMethod,
    String? description,
    String? deliveryNote,
  }) {
    final trimmedAddressId = addressId?.trim();
    if (trimmedAddressId == null || trimmedAddressId.isEmpty) {
      return (
        payload: const {},
        failure: const ValidationFailure(checkoutAddressRequiredMessage),
      );
    }

    final normalizedPaymentMethod = _normalizePaymentMethod(paymentMethod);
    if (normalizedPaymentMethod == null) {
      return (
        payload: const {},
        failure: const ValidationFailure(checkoutPaymentRequiredMessage),
      );
    }

    final hasCartItems = cartItems.isNotEmpty;
    final itemPayloads = <Map<String, int>>[];
    if (hasCartItems) {
      for (final item in cartItems.where((item) => !item.isOffer)) {
        final itemResult = _productPayload(
          variantId: item.variantId,
          quantity: item.quantity,
        );
        if (itemResult.failure case final failure?) {
          return (payload: const {}, failure: failure);
        }
        itemPayloads.add(itemResult.payload!);
      }
    } else {
      for (final item in orderItems) {
        final itemResult = _productPayload(
          variantId: item.variantId,
          quantity: item.quantity,
        );
        if (itemResult.failure case final failure?) {
          return (payload: const {}, failure: failure);
        }
        itemPayloads.add(itemResult.payload!);
      }
    }

    final offerPayloads = <Map<String, int>>[];
    for (final item in cartItems.where((item) => item.isOffer)) {
      final offerId = _offerIdFromCartItem(item);
      if (offerId == null) {
        return (
          payload: const {},
          failure: const ValidationFailure(
            'Some offer items are missing valid offer information. Please add them again.',
          ),
        );
      }
      offerPayloads.add({'offer_id': offerId});
    }

    if (itemPayloads.isEmpty && offerPayloads.isEmpty) {
      return (
        payload: const {},
        failure: const ValidationFailure(
          'Add at least one product or offer before checkout.',
        ),
      );
    }

    return (
      failure: null,
      payload: {
        'address_id': _idFromString(trimmedAddressId),
        'payment_method': normalizedPaymentMethod,
        'description': description?.trim() ?? '',
        'delivery_note': deliveryNote?.trim() ?? '',
        'items': itemPayloads,
        'offers': offerPayloads,
      },
    );
  }
}

({Map<String, int>? payload, ValidationFailure? failure}) _productPayload({
  required String? variantId,
  required int quantity,
}) {
  final parsedVariantId = _positiveIdFromValue(variantId);
  if (parsedVariantId == null) {
    return (
      payload: null,
      failure: const ValidationFailure(
        'Some cart items are missing variant information. Please add them again.',
      ),
    );
  }
  if (quantity <= 0) {
    return (
      payload: null,
      failure: const ValidationFailure(
        'Cart items must have a quantity greater than zero.',
      ),
    );
  }
  return (
    payload: {'variant_id': parsedVariantId, 'quantity': quantity},
    failure: null,
  );
}

String? _normalizePaymentMethod(String? paymentMethod) {
  final value = paymentMethod?.trim().toLowerCase();
  if (value == null || value.isEmpty) return 'cash';
  if (value == 'cash' || value == 'cash_on_delivery') return 'cash';
  return null;
}

Failure _checkoutError(DioException error) {
  final statusCode = error.response?.statusCode;
  final data = error.response?.data;
  if (data is Map) {
    if (_truthy(data['requires_region_selection'])) {
      return ValidationFailure(
        checkoutRegionRequiredMessage,
        statusCode: statusCode,
      );
    }
    if (_truthy(data['requires_address_selection']) ||
        data.containsKey('address_id') ||
        data.containsKey('delivery_address_id')) {
      return ValidationFailure(
        checkoutAddressRequiredMessage,
        statusCode: statusCode,
      );
    }
    if (data.containsKey('payment_method')) {
      return ValidationFailure(
        checkoutPaymentRequiredMessage,
        statusCode: statusCode,
      );
    }
    if (data.containsKey('items')) {
      return ValidationFailure(
        _arabicMessageFrom(data['items']) ?? checkoutItemsInvalidMessage,
        statusCode: statusCode,
      );
    }
    if (data.containsKey('offers')) {
      return ValidationFailure(
        _arabicMessageFrom(data['offers']) ?? checkoutOffersInvalidMessage,
        statusCode: statusCode,
      );
    }
    if (data.containsKey('non_field_errors')) {
      return ValidationFailure(
        _arabicMessageFrom(data['non_field_errors']) ??
            checkoutOrderInvalidMessage,
        statusCode: statusCode,
      );
    }
    if (_mentionsRegionSelection(data['message'])) {
      return ValidationFailure(
        checkoutRegionRequiredMessage,
        statusCode: statusCode,
      );
    }
  }

  final fallback = ApiErrorHandler.handle(error);
  if (_isSuppressedCheckoutMessage(fallback.message)) {
    return ValidationFailure(
      checkoutOrderInvalidMessage,
      statusCode: statusCode,
    );
  }
  return fallback;
}

bool _truthy(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  if (value is Iterable) return value.any(_truthy);
  return false;
}

bool _mentionsRegionSelection(Object? value) {
  final messages = <String>[];
  _collectMessages(value, messages);
  return messages.any(
    (message) => message.toLowerCase().contains('market browsing region'),
  );
}

String? _arabicMessageFrom(Object? value) {
  final messages = <String>[];
  _collectMessages(value, messages);
  for (final message in messages) {
    if (_isSuppressedCheckoutMessage(message)) continue;
    if (_containsArabic(message)) return message;
  }
  return null;
}

void _collectMessages(Object? value, List<String> messages) {
  if (value is String && value.trim().isNotEmpty) {
    messages.add(value.trim());
    return;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      if (entry.key == 'current_selection') continue;
      _collectMessages(entry.value, messages);
    }
    return;
  }
  if (value is Iterable) {
    for (final item in value) {
      _collectMessages(item, messages);
    }
  }
}

bool _containsArabic(String value) =>
    RegExp(r'[\u0600-\u06FF]').hasMatch(value);

bool _isSuppressedCheckoutMessage(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ||
      normalized == 'true' ||
      normalized == 'none' ||
      normalized == 'this field is required.' ||
      normalized == 'current_selection';
}

int? _offerIdFromCartItem(CartItemData item) {
  return _offerIdFromValue(item.productId) ?? _offerIdFromValue(item.id);
}

Object? _idFromString(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return int.tryParse(trimmed) ?? trimmed;
}

int? _positiveIdFromValue(Object? value) {
  final id = _offerIdFromValue(value);
  return id != null && id > 0 ? id : null;
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
