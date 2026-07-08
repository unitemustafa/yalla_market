import '../../../../core/network/api_result.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../entities/order_preview.dart';
import '../repositories/order_repository.dart';

class PreviewOrderUseCase {
  const PreviewOrderUseCase(this._repository);

  final OrderRepository _repository;

  Future<ApiResult<OrderPreviewData>> call({
    required List<CartItemData> cartItems,
    required String addressId,
    String? paymentMethod,
    String? description,
    String? deliveryNote,
  }) {
    return _repository.previewOrder(
      cartItems: cartItems,
      addressId: addressId,
      paymentMethod: paymentMethod,
      description: description,
      deliveryNote: deliveryNote,
    );
  }
}
