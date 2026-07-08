import 'dart:math';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_preview.dart';
import '../../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final List<OrderData> _orders = [];
  final Random _random = Random.secure();

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
  }) async {
    if (items.isEmpty) {
      return const ApiResult.failure(
        ValidationFailure('Cannot create an order without items.'),
      );
    }

    if (items.any((item) => item.quantity <= 0 || item.unitPrice < 0)) {
      return const ApiResult.failure(
        ValidationFailure('Order items contain invalid quantities or prices.'),
      );
    }

    try {
      final now = DateTime.now();
      final subtotal = items.fold<double>(
        0,
        (sum, item) => sum + item.lineTotal,
      );
      final total = subtotal + shippingFee + taxTotal - discountTotal;
      final normalizedPaymentMethod = paymentMethod?.trim();
      final order = OrderData(
        id: 'local-order-${now.microsecondsSinceEpoch}',
        orderNumber: _randomOrderNumber(now),
        status: OrderStatus.processing,
        placedAt: now,
        estimatedDeliveryAt: now.add(const Duration(days: 5)),
        shippingAddress: shippingAddress,
        paymentMethod:
            normalizedPaymentMethod == null || normalizedPaymentMethod.isEmpty
            ? 'cash'
            : normalizedPaymentMethod,
        items: List.unmodifiable(items),
        subtotal: subtotal,
        shippingFee: shippingFee,
        deliveryType: deliveryType == 'manual_quote'
            ? OrderDeliveryType.manualQuote
            : OrderDeliveryType.fixedArea,
        deliveryPriceStatus: deliveryType == 'manual_quote'
            ? OrderDeliveryPriceStatus.pendingQuote
            : OrderDeliveryPriceStatus.fixed,
        customDeliveryArea: customDeliveryArea ?? '',
        deliveryLabel: deliveryType == 'manual_quote' ? 'دليفري' : '',
        taxTotal: taxTotal,
        discountTotal: discountTotal,
        total: total < 0 ? 0 : total,
      );

      _orders.insert(0, order);
      return ApiResult.success([order]);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not create your order.'),
      );
    }
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    try {
      return ApiResult.success(List.unmodifiable(_orders));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load your orders.'),
      );
    }
  }

  @override
  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
    required String addressId,
    String? paymentMethod,
    String? description,
    String? deliveryNote,
  }) async {
    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );

    return ApiResult.success(
      OrderPreviewData(
        summary: OrderPreviewSummaryData(
          subtotal: subtotal,
          discountTotal: 0,
          deliveryTotal: 0,
          grandTotal: subtotal,
        ),
      ),
    );
  }

  String _randomOrderNumber(DateTime now) {
    final dateStamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return 'YM-$dateStamp-${_randomSegment()}';
  }

  String _randomSegment([int length = 6]) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }
}
