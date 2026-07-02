import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_preview.dart';
import '../../domain/repositories/order_repository.dart';

const orderCreationUnavailableMessage =
    'إنشاء الطلبات غير متاح حاليًا لحين تجهيز الباك';

class OrderUnavailableRepositoryImpl implements OrderRepository {
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

  @override
  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
  }) async {
    return const ApiResult.failure(
      ValidationFailure('Order preview is not available yet.'),
    );
  }
}
