import '../../../../core/network/api_result.dart';
import '../entities/order.dart';

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
}
