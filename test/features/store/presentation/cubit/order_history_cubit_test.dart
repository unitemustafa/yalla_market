import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/accept_delivery_quote_usecase.dart';
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

    test('preserves a loaded empty result when a refresh fails', () async {
      final repository = _FakeOrderRepository(orders: const []);
      final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));
      await cubit.loadOrders();
      final delay = Completer<void>();
      repository.nextDelay = delay;
      repository.nextFailure = const ServerFailure('Orders are unavailable.');

      final refresh = cubit.loadOrders(force: true);
      await Future<void>.delayed(Duration.zero);

      final loading = cubit.state as OrderHistoryLoading;
      expect(loading.orders, isEmpty);
      expect(loading.hasLoaded, isTrue);

      delay.complete();
      await refresh;

      final failure = cubit.state as OrderHistoryFailure;
      expect(failure.orders, isEmpty);
      expect(failure.hasLoaded, isTrue);
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
      var secondLoadFinished = false;
      secondLoad.whenComplete(() => secondLoadFinished = true);
      await Future<void>.delayed(Duration.zero);

      expect(repository.getMyOrdersCalls, 1);
      expect(secondLoadFinished, isFalse);

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

    test(
      'clearSession ignores an order response from the old session',
      () async {
        final delay = Completer<void>();
        final repository = _FakeOrderRepository(
          orders: [sampleOrder],
          delay: delay,
        );
        final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));

        final load = cubit.loadOrders();
        cubit.clearSession();
        delay.complete();
        await load;

        expect(cubit.state, isA<OrderHistoryInitial>());
        await cubit.close();
      },
    );

    test('retries delivery quote approval after a failure', () async {
      final pendingOrder = _deliveryQuoteOrder(
        OrderDeliveryPriceStatus.awaitingCustomerApproval,
      );
      final acceptedOrder = _deliveryQuoteOrder(OrderDeliveryPriceStatus.fixed);
      final repository = _FakeOrderRepository(
        orders: [pendingOrder],
        deliveryQuoteResults: [
          const ApiResult.failure(ServerFailure('Approval is unavailable.')),
          ApiResult.success(acceptedOrder),
        ],
      );
      final cubit = OrderHistoryCubit(
        GetMyOrdersUseCase(repository),
        AcceptDeliveryQuoteUseCase(repository),
      );
      await cubit.loadOrders();

      final firstError = await cubit.acceptDeliveryQuote(pendingOrder.id);

      expect(firstError, 'Approval is unavailable.');
      expect(
        (cubit.state as OrderHistoryReady).orders.single.deliveryPriceStatus,
        OrderDeliveryPriceStatus.awaitingCustomerApproval,
      );

      final retryError = await cubit.acceptDeliveryQuote(pendingOrder.id);

      expect(retryError, isNull);
      expect(repository.acceptDeliveryQuoteCalls, 2);
      expect(
        (cubit.state as OrderHistoryReady).orders.single.deliveryPriceStatus,
        OrderDeliveryPriceStatus.fixed,
      );
      await cubit.close();
    });
  });
}

OrderData _deliveryQuoteOrder(OrderDeliveryPriceStatus deliveryPriceStatus) {
  return OrderData(
    id: sampleOrder.id,
    orderNumber: sampleOrder.orderNumber,
    status: sampleOrder.status,
    placedAt: sampleOrder.placedAt,
    shippingAddress: sampleOrder.shippingAddress,
    paymentMethod: sampleOrder.paymentMethod,
    items: sampleOrder.items,
    subtotal: sampleOrder.subtotal,
    shippingFee: sampleOrder.shippingFee,
    deliveryPriceStatus: deliveryPriceStatus,
    taxTotal: sampleOrder.taxTotal,
    discountTotal: sampleOrder.discountTotal,
    total: sampleOrder.total,
  );
}

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository({
    required this.orders,
    Completer<void>? delay,
    this.deliveryQuoteResults = const [],
  }) : _delay = delay;

  final List<OrderData> orders;
  final Completer<void>? _delay;
  Completer<void>? nextDelay;
  Failure? nextFailure;
  int getMyOrdersCalls = 0;
  final List<ApiResult<OrderData>> deliveryQuoteResults;
  int acceptDeliveryQuoteCalls = 0;

  @override
  Future<ApiResult<OrderData>> acceptDeliveryQuote(String orderId) async {
    acceptDeliveryQuoteCalls += 1;
    if (deliveryQuoteResults.isEmpty) {
      return const ApiResult.failure(
        ValidationFailure('Delivery quote approval is not used in this test.'),
      );
    }
    return deliveryQuoteResults.removeAt(0);
  }

  void completeDelay() {
    final delay = _delay;
    if (delay != null && !delay.isCompleted) delay.complete();
  }

  @override
  Future<ApiResult<List<OrderData>>> createOrder({
    required ShippingAddressData shippingAddress,
    required List<OrderItemData> items,
    List<CartItemData> cartItems = const [],
    String? paymentMethod,
    String? deliveryType,
    String? customDeliveryArea,
    String? deliveryAreaId,
    int? shippingCompanyId,
    String? description,
    String? deliveryNote,
    double shippingFee = 0,
    double taxTotal = 0,
    double discountTotal = 0,
  }) async {
    return ApiResult.success([sampleOrder]);
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    getMyOrdersCalls += 1;
    final delay = nextDelay ?? _delay;
    nextDelay = null;
    await delay?.future;

    if (nextFailure case final failure?) {
      nextFailure = null;
      return ApiResult.failure(failure);
    }

    return ApiResult.success(orders);
  }

  @override
  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
    required String addressId,
    String? paymentMethod,
    String? description,
    String? deliveryNote,
  }) async {
    return const ApiResult.failure(
      ValidationFailure('Order preview is not used in this test.'),
    );
  }
}
