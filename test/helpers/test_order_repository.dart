import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';

/// Minimal repository for widget and Cubit tests that only need preview and
/// empty-history behavior. Tests for successful creation provide their own
/// purpose-built repository.
class TestOrderRepository implements OrderRepository {
  @override
  Future<ApiResult<List<OrderData>>> createOrder({
    required ShippingAddressData shippingAddress,
    required List<OrderItemData> items,
    List<CartItemData> cartItems = const [],
    String? paymentMethod,
    String? deliveryType,
    String? customDeliveryArea,
    String? deliveryAreaId,
    int? shippingCompanyId,
    String? description,
    String? deliveryNote,
    double shippingFee = 0,
    double taxTotal = 0,
    double discountTotal = 0,
  }) async {
    return const ApiResult.failure(
      ValidationFailure('Order creation is not configured for this test.'),
    );
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<OrderData>> acceptDeliveryQuote(String orderId) async {
    return const ApiResult.failure(ValidationFailure('Order was not found.'));
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
}
