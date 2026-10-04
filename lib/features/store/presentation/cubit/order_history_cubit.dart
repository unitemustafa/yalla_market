import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/data_freshness.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/coalesced_operation.dart';

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
  final _loads = CoalescedOperation();
  int _generation = 0;
  final DataFreshness _freshness = DataFreshness();

  DateTime? get lastNetworkSuccessAt => _freshness.lastNetworkSuccessAt;

  Future<void> refreshIfStale() async {
    if (_freshness.isStale) await loadOrders(force: true);
  }

  void clearSession() {
    _loads.reset();
    _generation++;
    _freshness.invalidate();
    emit(const OrderHistoryInitial());
  }

  Future<void> loadOrders({bool force = false}) =>
      _loads.run(() => _loadOrders(force: force));

  Future<void> _loadOrders({bool force = false}) async {
    if (!force && state is OrderHistoryReady && !_freshness.isStale) return;

    final generation = _generation;
    final staleOrders = switch (state) {
      OrderHistoryReady(:final orders) => orders,
      OrderHistoryFailure(:final orders) => orders,
      OrderHistoryLoading(:final orders) => orders,
      _ => const <OrderData>[],
    };

    final hasLoaded = state.hasLoaded || staleOrders.isNotEmpty;
    emit(OrderHistoryLoading(orders: staleOrders, hasLoaded: hasLoaded));

    final result = await _getMyOrdersUseCase();
    if (generation != _generation || isClosed) return;
    if (result case ApiSuccess(origin: DataOrigin.network)) {
      _freshness.markNetworkSuccess();
    }
    result.when(
      success: (orders) {
        emit(OrderHistoryReady(orders));
      },
      failure: (failure) {
        emit(
          OrderHistoryFailure(
            failure.message,
            orders: staleOrders,
            hasLoaded: hasLoaded,
          ),
        );
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
