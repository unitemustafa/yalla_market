import '../../../../core/network/api_result.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

abstract interface class OrderHistorySupplement {
  List<OrderData> fallbackOrders();
}

class EmptyOrderHistorySupplement implements OrderHistorySupplement {
  const EmptyOrderHistorySupplement();

  @override
  List<OrderData> fallbackOrders() => const [];
}

class GetMyOrdersUseCase {
  const GetMyOrdersUseCase(
    this._repository, {
    OrderHistorySupplement supplement = const EmptyOrderHistorySupplement(),
  }) : _supplement = supplement;

  final OrderRepository _repository;
  final OrderHistorySupplement _supplement;

  Future<ApiResult<List<OrderData>>> call() async {
    final result = await _repository.getMyOrders();
    return result.when(
      success: (orders) => ApiResult.success(
        orders.isEmpty ? _supplement.fallbackOrders() : orders,
      ),
      failure: ApiResult.failure,
    );
  }
}
