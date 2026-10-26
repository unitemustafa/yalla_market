import '../../domain/entities/order.dart';

sealed class OrderHistoryState {
  const OrderHistoryState();

  bool get hasLoaded => false;
  int? get totalCount => null;
  int? get deliveredCount => null;
}

final class OrderHistoryInitial extends OrderHistoryState {
  const OrderHistoryInitial();
}

final class OrderHistoryLoading extends OrderHistoryState {
  const OrderHistoryLoading({
    this.orders = const [],
    this.hasLoaded = false,
    this.totalCount,
    this.deliveredCount,
  });
  @override
  final int? totalCount;
  @override
  final int? deliveredCount;

  @override
  final bool hasLoaded;

  final List<OrderData> orders;
}

final class OrderHistoryReady extends OrderHistoryState {
  const OrderHistoryReady(
    this.orders, {
    this.totalCount,
    this.deliveredCount,
    this.hasMore = false,
    this.loadingMore = false,
    this.moreError,
    this.updatedOrder,
  });
  @override
  final int? totalCount;
  @override
  final int? deliveredCount;
  final bool hasMore;
  final bool loadingMore;
  final String? moreError;
  final OrderData? updatedOrder;

  @override
  bool get hasLoaded => true;

  final List<OrderData> orders;
}

final class OrderHistoryFailure extends OrderHistoryState {
  const OrderHistoryFailure(
    this.message, {
    this.orders = const [],
    this.hasLoaded = false,
    this.totalCount,
    this.deliveredCount,
  });

  @override
  final bool hasLoaded;

  final String message;
  @override
  final int? totalCount;
  @override
  final int? deliveredCount;

  /// Stale orders to show while the error is displayed (may be empty).
  final List<OrderData> orders;
}
