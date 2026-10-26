import '../../../../core/network/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';
import '../entities/order_history_page.dart';

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

  Future<ApiResult<OrderData?>> findOrder(String orderId) async {
    if (int.tryParse(orderId) case final id? when id > 0) {
      final repository = _repository;
      if (repository is FocusedOrderRepository) {
        return (repository as FocusedOrderRepository).findOrder(orderId);
      }
      final result = await call();
      return result.when(
        success: (orders) => ApiResult.success(
          orders.where((order) => order.id == orderId).firstOrNull,
        ),
        failure: ApiResult.failure,
      );
    }
    return const ApiResult.failure(ValidationFailure('Invalid order.'));
  }

  Future<ApiResult<OrderHistoryPage>> page({
    int page = 1,
    DateTime? start,
    DateTime? end,
  }) async {
    if (page < 1 || (start != null && end != null && end.isBefore(start))) {
      return const ApiResult.failure(
        ValidationFailure('Invalid order history range.'),
      );
    }
    final repository = _repository;
    if (repository is PagedOrderHistoryRepository) {
      return (repository as PagedOrderHistoryRepository).getOrderPage(
        page: page,
        start: start,
        end: end,
      );
    }
    final result = await call();
    return result.when(
      success: (items) {
        final filtered = items
            .where((o) {
              final date = DateTime(
                o.placedAt.year,
                o.placedAt.month,
                o.placedAt.day,
              );
              return (start == null ||
                      !date.isBefore(
                        DateTime(start.year, start.month, start.day),
                      )) &&
                  (end == null ||
                      !date.isAfter(DateTime(end.year, end.month, end.day)));
            })
            .toList(growable: false);
        return ApiResult.success(
          OrderHistoryPage(
            items: filtered,
            count: filtered.length,
            hasMore: false,
            deliveredCount: filtered
                .where((o) => o.status == OrderStatus.delivered)
                .length,
          ),
        );
      },
      failure: ApiResult.failure,
    );
  }

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
