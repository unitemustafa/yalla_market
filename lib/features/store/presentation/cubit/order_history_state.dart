import '../../domain/entities/order.dart';

sealed class OrderHistoryState {
  const OrderHistoryState();

  bool get hasLoaded => false;
}

final class OrderHistoryInitial extends OrderHistoryState {
  const OrderHistoryInitial();
}

final class OrderHistoryLoading extends OrderHistoryState {
  const OrderHistoryLoading({this.orders = const [], this.hasLoaded = false});

  @override
  final bool hasLoaded;

  final List<OrderData> orders;
}

final class OrderHistoryReady extends OrderHistoryState {
  const OrderHistoryReady(this.orders);

  @override
  bool get hasLoaded => true;

  final List<OrderData> orders;
}

final class OrderHistoryFailure extends OrderHistoryState {
  const OrderHistoryFailure(
    this.message, {
    this.orders = const [],
    this.hasLoaded = false,
  });

  @override
  final bool hasLoaded;

  final String message;

  /// Stale orders to show while the error is displayed (may be empty).
  final List<OrderData> orders;
}
