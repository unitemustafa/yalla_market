import '../../../../core/network/api_result.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../entities/order.dart';
import '../entities/order_preview.dart';

abstract class OrderRepository {
  Future<ApiResult<OrderData>> createOrder({
    required ShippingAddressData shippingAddress,
    required List<OrderItemData> items,
    String? paymentMethod,
    String? deliveryType,
    String? customDeliveryArea,
    String? deliveryAreaId,
    double shippingFee,
    double taxTotal,
    double discountTotal,
  });

  Future<ApiResult<List<OrderData>>> getMyOrders();

  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
  });
}
