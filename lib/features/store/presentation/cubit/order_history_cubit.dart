import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/data_freshness.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/coalesced_operation.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_history_page.dart';
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
  int _sessionGeneration = 0;
  int _page = 1;
  DateTime? _start;
  DateTime? _end;
  bool _moreLoading = false;
  Future<void> selectRange(DateTime? start, DateTime? end) async {
    if (_start == start && _end == end) {
      return;
    }
    _start = start;
    _end = end;
    _moreLoading = false;
    _generation++;
    _loads.reset();
    emit(const OrderHistoryInitial());
    await loadOrders(force: true);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! OrderHistoryReady ||
        !current.hasMore ||
        current.loadingMore ||
        _moreLoading ||
        _loads.isRunning) {
      return;
    }
    _moreLoading = true;
    final generation = _generation;
    emit(
      OrderHistoryReady(
        current.orders,
        totalCount: current.totalCount,
        deliveredCount: current.deliveredCount,
        hasMore: true,
        loadingMore: true,
      ),
    );
    final result = await _getMyOrdersUseCase.page(
      page: _page + 1,
      start: _start,
      end: _end,
    );
    if (isClosed || generation != _generation) {
      return;
    }
    _moreLoading = false;
    result.when(
      success: (page) {
        _page++;
        final live = state is OrderHistoryReady
            ? (state as OrderHistoryReady).orders
            : current.orders;
        final merged = {
          for (final o in live) o.id: o,
          for (final o in page.items) o.id: o,
        };
        emit(
          OrderHistoryReady(
            List.unmodifiable(merged.values),
            totalCount: page.count,
            deliveredCount: page.deliveredCount,
            hasMore: page.hasMore,
          ),
        );
      },
      failure: (failure) => emit(
        OrderHistoryReady(
          state is OrderHistoryReady
              ? (state as OrderHistoryReady).orders
              : current.orders,
          totalCount: current.totalCount,
          deliveredCount: current.deliveredCount,
          hasMore: true,
          moreError: failure.message,
        ),
      ),
    );
  }

  final DataFreshness _freshness = DataFreshness();

  DateTime? get lastNetworkSuccessAt => _freshness.lastNetworkSuccessAt;

  Future<void> refreshIfStale() async {
    if (_freshness.isStale) await loadOrders(force: true);
  }

  void clearSession() {
    _sessionGeneration++;
    _loads.reset();
    _generation++;
    _freshness.invalidate();
    _page = 1;
    _start = null;
    _end = null;
    _moreLoading = false;
    emit(const OrderHistoryInitial());
  }

  Future<void> loadOrders({bool force = false}) =>
      _loads.run(() => _loadOrders(force: force));

  Future<void> _loadOrders({bool force = false}) async {
    if (!force && state is OrderHistoryReady && !_freshness.isStale) return;

    _moreLoading = false;
    final generation = ++_generation;
    final staleOrders = switch (state) {
      OrderHistoryReady(:final orders) => orders,
      OrderHistoryFailure(:final orders) => orders,
      OrderHistoryLoading(:final orders) => orders,
      _ => const <OrderData>[],
    };

    final hasLoaded = state.hasLoaded || staleOrders.isNotEmpty;
    final pages = hasLoaded ? _page : 1;
    final total = state.totalCount;
    final delivered = state.deliveredCount;
    emit(
      OrderHistoryLoading(
        orders: staleOrders,
        hasLoaded: hasLoaded,
        totalCount: total,
        deliveredCount: delivered,
      ),
    );

    ApiResult<OrderHistoryPage>? result;
    final merged = <String, OrderData>{};
    var loadedPage = 0;
    for (var number = 1; number <= pages; number++) {
      result = await _getMyOrdersUseCase.page(
        page: number,
        start: _start,
        end: _end,
      );
      if (generation != _generation || isClosed) return;
      if (result case ApiFailure()) break;
      final data = (result as ApiSuccess<OrderHistoryPage>).data;
      loadedPage = number;
      for (final item in data.items) {
        merged[item.id] = item;
      }
      if (!data.hasMore) break;
    }
    if (result == null) return;
    if (generation != _generation || isClosed) return;
    if (result case ApiSuccess(origin: DataOrigin.network)) {
      _freshness.markNetworkSuccess();
    }
    result.when(
      success: (page) {
        _page = loadedPage;
        emit(
          OrderHistoryReady(
            List.unmodifiable(merged.values),
            totalCount: page.count,
            deliveredCount: page.deliveredCount,
            hasMore: page.hasMore,
          ),
        );
      },
      failure: (failure) {
        emit(
          OrderHistoryFailure(
            failure.message,
            orders: staleOrders,
            hasLoaded: hasLoaded,
            totalCount: total,
            deliveredCount: delivered,
          ),
        );
      },
    );
  }

  Future<ApiResult<OrderData?>> findOrder(String orderId) =>
      _getMyOrdersUseCase.findOrder(orderId);

  Future<String?> acceptDeliveryQuote(String orderId) async {
    final useCase = _acceptDeliveryQuoteUseCase;
    if (useCase == null) return 'Delivery price approval is not available.';
    final generation = _sessionGeneration;
    final result = await useCase(orderId);
    if (isClosed || generation != _sessionGeneration) return null;
    String? errorMessage;
    result.when(
      success: (updatedOrder) {
        if (_loads.isRunning) {
          unawaited(() async {
            await _loads.run(() async {});
            if (!isClosed && generation == _sessionGeneration) {
              await loadOrders(force: true);
            }
          }());
        }
        final currentOrders = switch (state) {
          OrderHistoryReady(:final orders) => orders,
          OrderHistoryFailure(:final orders) => orders,
          OrderHistoryLoading(:final orders) => orders,
          _ => const <OrderData>[],
        };
        final updatedOrders = currentOrders
            .map((order) => order.id == updatedOrder.id ? updatedOrder : order)
            .toList(growable: false);
        final previous = state;
        emit(
          OrderHistoryReady(
            updatedOrders,
            totalCount: previous.totalCount,
            deliveredCount: previous.deliveredCount,
            hasMore: previous is OrderHistoryReady && previous.hasMore,
            loadingMore: previous is OrderHistoryReady && previous.loadingMore,
            updatedOrder: updatedOrder,
          ),
        );
      },
      failure: (failure) => errorMessage = failure.message,
    );
    return errorMessage;
  }
}
