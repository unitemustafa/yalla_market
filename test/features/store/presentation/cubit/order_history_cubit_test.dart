import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_my_orders_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_state.dart';

import '../../../../helpers/domain_fixtures.dart';

void main() {
  group('OrderHistoryCubit', () {
    test('loads current customer orders', () async {
      final repository = _FakeOrderRepository(orders: [sampleOrder]);
      final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<OrderHistoryLoading>(), isA<OrderHistoryReady>()]),
      );

      await cubit.loadOrders();

      final state = cubit.state as OrderHistoryReady;
      expect(state.orders.single.id, sampleOrder.id);
      await expectedStates;
      await cubit.close();
    });

    test('preserves stale orders when refreshing fails', () async {
      final repository = _FakeOrderRepository(orders: [sampleOrder]);
      final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));
      await cubit.loadOrders();
      repository.nextFailure = const ServerFailure('Orders are unavailable.');

      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<OrderHistoryLoading>(), isA<OrderHistoryFailure>()]),
      );
      await cubit.loadOrders(force: true);

      final state = cubit.state as OrderHistoryFailure;
      expect(state.message, 'Orders are unavailable.');
      expect(state.orders.single.id, sampleOrder.id);
      await expectedStates;
      await cubit.close();
    });

    test('does not reload ready orders unless forced', () async {
      final repository = _FakeOrderRepository(orders: [sampleOrder]);
      final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));

      await cubit.loadOrders();
      await cubit.loadOrders();

      expect(repository.getMyOrdersCalls, 1);

      await cubit.loadOrders(force: true);

      expect(repository.getMyOrdersCalls, 2);
      await cubit.close();
    });

    test('does not start parallel loads while loading', () async {
      final repository = _FakeOrderRepository(
        orders: [sampleOrder],
        delay: Completer<void>(),
      );
      final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));

      final firstLoad = cubit.loadOrders();
      final secondLoad = cubit.loadOrders(force: true);

      expect(repository.getMyOrdersCalls, 1);

      repository.completeDelay();
      await Future.wait([firstLoad, secondLoad]);

      expect(cubit.state, isA<OrderHistoryReady>());
      expect(repository.getMyOrdersCalls, 1);
      await cubit.close();
    });

    test('clearSession resets order history state', () async {
      final repository = _FakeOrderRepository(orders: [sampleOrder]);
      final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));
      await cubit.loadOrders();

      cubit.clearSession();

      expect(cubit.state, isA<OrderHistoryInitial>());
      await cubit.close();
    });
  });
}

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository({required this.orders, Completer<void>? delay})
    : _delay = delay;

  final List<OrderData> orders;
  final Completer<void>? _delay;
  Failure? nextFailure;
  int getMyOrdersCalls = 0;

  void completeDelay() {
    final delay = _delay;
    if (delay != null && !delay.isCompleted) delay.complete();
  }

  @override
  Future<ApiResult<OrderData>> createOrder({
    required ShippingAddressData shippingAddress,
    required List<OrderItemData> items,
    List<CartItemData> cartItems = const [],
    String? paymentMethod,
    String? deliveryType,
    String? customDeliveryArea,
    String? deliveryAreaId,
    String? description,
    String? deliveryNote,
    double shippingFee = 0,
    double taxTotal = 0,
    double discountTotal = 0,
  }) async {
    return ApiResult.success(sampleOrder);
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    getMyOrdersCalls += 1;
    await _delay?.future;

    if (nextFailure case final failure?) {
      nextFailure = null;
      return ApiResult.failure(failure);
    }

    return ApiResult.success(orders);
  }

  @override
  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
  }) async {
    return const ApiResult.failure(
      ValidationFailure('Order preview is not used in this test.'),
    );
  }
}
