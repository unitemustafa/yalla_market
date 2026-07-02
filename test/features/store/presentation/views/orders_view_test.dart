import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_my_orders_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/orders/orders_view.dart';

void main() {
  testWidgets(
    'shows a real empty state instead of demo orders in backend mode',
    (tester) async {
      final orderHistoryCubit = OrderHistoryCubit(
        GetMyOrdersUseCase(_EmptyOrderRepository()),
      );
      addTearDown(orderHistoryCubit.close);

      await tester.pumpWidget(
        BlocProvider<OrderHistoryCubit>.value(
          value: orderHistoryCubit,
          child: const MaterialApp(home: OrdersView(useDemoOrders: false)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No orders yet'), findsOneWidget);
      expect(
        find.text('Your orders will appear here once you place an order.'),
        findsOneWidget,
      );
      expect(find.text('CWT0012'), findsNothing);
    },
  );
}

class _EmptyOrderRepository implements OrderRepository {
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
    return const ApiResult.failure(
      ValidationFailure('Order creation is not used in this test.'),
    );
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    return const ApiResult.success([]);
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
