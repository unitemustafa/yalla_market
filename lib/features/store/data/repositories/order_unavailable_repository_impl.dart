import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

const orderCreationUnavailableMessage =
    'إنشاء الطلبات غير متاح حاليًا لحين تجهيز الباك';

class OrderUnavailableRepositoryImpl implements OrderRepository {
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
  }) async {
    return const ApiResult.failure(
      ValidationFailure(orderCreationUnavailableMessage),
    );
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    return const ApiResult.failure(
      ValidationFailure('Order history is not available yet.'),
    );
  }
}
