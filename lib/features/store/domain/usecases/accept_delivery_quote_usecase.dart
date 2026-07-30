import '../../../../core/network/api_result.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class AcceptDeliveryQuoteUseCase {
  const AcceptDeliveryQuoteUseCase(this._repository);

  final OrderRepository _repository;

  Future<ApiResult<OrderData>> call(String orderId) {
    return _repository.acceptDeliveryQuote(orderId);
  }
}
