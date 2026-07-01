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
    String? paymentMethod,
    String? deliveryType,
    String? customDeliveryArea,
    String? deliveryAreaId,
    double shippingFee = 0,
    double taxTotal = 0,
    double discountTotal = 0,
  }) {
    return _guard(() async {
      final payload = await _apiClient.post<Map<String, dynamic>>(
        '/orders/',
        data: {
          'delivery_address_id': int.tryParse(shippingAddress.id ?? ''),
          if (deliveryAreaId != null && deliveryAreaId.trim().isNotEmpty)
            'delivery_area_id': int.tryParse(deliveryAreaId),
          if (deliveryType != null && deliveryType.trim().isNotEmpty)
            'delivery_type': deliveryType,
          if (customDeliveryArea != null &&
              customDeliveryArea.trim().isNotEmpty)
            'custom_delivery_area': customDeliveryArea.trim(),
          'items': items
              .map(
                (item) => {
                  'variant_id': int.tryParse(item.variantId ?? item.id),
                  'quantity': item.quantity,
                },
              )
              .toList(),
          'payment_method': 'cash_on_delivery',
          'delivery_price': shippingFee,
          'discount': discountTotal,
        },
      );
      return OrderData.fromJson(payload);
    });
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
              .map(
                (item) => {
                  'offer_id': _idFromString(item.productId ?? item.id),
                },
              )
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

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(UnknownFailure('Could not load orders.'));
    }
  }
}

Object? _idFromString(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return int.tryParse(trimmed) ?? trimmed;
}
