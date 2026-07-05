import '../../../../core/network/api_result.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class CreateOrderUseCase {
  const CreateOrderUseCase(this._repository);

  final OrderRepository _repository;

  Future<ApiResult<List<OrderData>>> call({
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
    return _repository.createOrder(
      shippingAddress: shippingAddress,
      items: items,
      cartItems: cartItems,
      paymentMethod: paymentMethod,
      deliveryType: deliveryType,
      customDeliveryArea: customDeliveryArea,
      deliveryAreaId: deliveryAreaId,
      description: description,
      deliveryNote: deliveryNote,
      shippingFee: shippingFee,
      taxTotal: taxTotal,
      discountTotal: discountTotal,
    );
  }
}
