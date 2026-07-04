import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order.dart';
import '../../domain/usecases/get_my_orders_usecase.dart';
import 'order_history_state.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  OrderHistoryCubit(this._getMyOrdersUseCase)
    : super(const OrderHistoryInitial());

  final GetMyOrdersUseCase _getMyOrdersUseCase;

  void clearSession() {
    emit(const OrderHistoryInitial());
  }

  Future<void> loadOrders({bool force = false}) async {
    if (state is OrderHistoryLoading) return;
    if (!force && state is OrderHistoryReady) return;

    final staleOrders = switch (state) {
      OrderHistoryReady(:final orders) => orders,
      OrderHistoryFailure(:final orders) => orders,
      OrderHistoryLoading(:final orders) => orders,
      _ => const <OrderData>[],
    };

    emit(OrderHistoryLoading(orders: staleOrders));

    final result = await _getMyOrdersUseCase();
    result.when(
      success: (orders) {
        emit(OrderHistoryReady(orders));
      },
      failure: (failure) {
        emit(OrderHistoryFailure(failure.message, orders: staleOrders));
      },
    );
  }
}
