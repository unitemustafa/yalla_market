import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order.dart';
import '../../domain/usecases/get_my_orders_usecase.dart';
import '../../domain/usecases/accept_delivery_quote_usecase.dart';
import 'order_history_state.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  OrderHistoryCubit(
    this._getMyOrdersUseCase, [
    this._acceptDeliveryQuoteUseCase,
  ]) : super(const OrderHistoryInitial());

  final GetMyOrdersUseCase _getMyOrdersUseCase;
  final AcceptDeliveryQuoteUseCase? _acceptDeliveryQuoteUseCase;
  int _generation = 0;

  void clearSession() {
    _generation++;
    emit(const OrderHistoryInitial());
  }

  Future<void> loadOrders({bool force = false}) async {
    if (state is OrderHistoryLoading) return;
    if (!force && state is OrderHistoryReady) return;

    final generation = _generation;
    final staleOrders = switch (state) {
      OrderHistoryReady(:final orders) => orders,
      OrderHistoryFailure(:final orders) => orders,
      OrderHistoryLoading(:final orders) => orders,
      _ => const <OrderData>[],
    };

    emit(OrderHistoryLoading(orders: staleOrders));

    final result = await _getMyOrdersUseCase();
    if (generation != _generation || isClosed) return;
    result.when(
      success: (orders) {
        emit(OrderHistoryReady(orders));
      },
      failure: (failure) {
        emit(OrderHistoryFailure(failure.message, orders: staleOrders));
      },
    );
  }

  Future<String?> acceptDeliveryQuote(String orderId) async {
    final useCase = _acceptDeliveryQuoteUseCase;
    if (useCase == null) return 'Delivery price approval is not available.';
    final generation = _generation;
    final result = await useCase(orderId);
    if (isClosed || generation != _generation) return null;
    String? errorMessage;
    result.when(
      success: (updatedOrder) {
        final currentOrders = switch (state) {
          OrderHistoryReady(:final orders) => orders,
          OrderHistoryFailure(:final orders) => orders,
          OrderHistoryLoading(:final orders) => orders,
          _ => const <OrderData>[],
        };
        final updatedOrders = currentOrders
            .map((order) => order.id == updatedOrder.id ? updatedOrder : order)
            .toList(growable: false);
        emit(OrderHistoryReady(updatedOrders));
      },
      failure: (failure) => errorMessage = failure.message,
    );
    return errorMessage;
  }
}
