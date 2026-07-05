import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/personalization/presentation/views/settings/settings_view.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_my_orders_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_cubit.dart';

import '../../../../../helpers/domain_fixtures.dart';

void main() {
  testWidgets('loads order count from settings without opening orders', (
    tester,
  ) async {
    final repository = _SettingsOrderRepository(
      orders: List<OrderData>.generate(12, (_) => sampleOrder),
    );
    final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<OrderHistoryCubit>.value(
        value: cubit,
        child: const MaterialApp(home: SettingsView()),
      ),
    );

    expect(find.text('0'), findsNothing);

    await tester.pumpAndSettle();

    expect(repository.getMyOrdersCalls, 1);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('shows placeholder while loading and 0 only after empty ready', (
    tester,
  ) async {
    final loadCompleter = Completer<void>();
    final repository = _SettingsOrderRepository(
      orders: const [],
      delay: loadCompleter,
    );
    final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<OrderHistoryCubit>.value(
        value: cubit,
        child: const MaterialApp(home: SettingsView()),
      ),
    );
    await tester.pump();

    expect(find.text('-'), findsOneWidget);
    expect(find.text('0'), findsNothing);

    loadCompleter.complete();
    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);
  });
}

class _SettingsOrderRepository implements OrderRepository {
  _SettingsOrderRepository({required this.orders, this.delay});

  final List<OrderData> orders;
  final Completer<void>? delay;
  int getMyOrdersCalls = 0;

  @override
  Future<ApiResult<List<OrderData>>> createOrder({
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
    return const ApiResult.failure(
      ValidationFailure('Order creation is not used in this test.'),
    );
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    getMyOrdersCalls += 1;
    await delay?.future;
    return ApiResult.success(orders);
  }

  @override
  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
    required String addressId,
  }) async {
    return const ApiResult.failure(
      ValidationFailure('Order preview is not used in this test.'),
    );
  }
}
