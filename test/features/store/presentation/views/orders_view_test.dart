import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_my_orders_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/orders/orders_view.dart';

void main() {
  testWidgets('refreshes cached orders when the orders page opens', (
    tester,
  ) async {
    final repository = _OrderRepositoryWithData([
      _orderPlacedAt(DateTime(2026, 7, 14), status: OrderStatus.processing),
    ]);
    final orderHistoryCubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));
    addTearDown(orderHistoryCubit.close);
    await orderHistoryCubit.loadOrders();

    await tester.pumpWidget(
      BlocProvider<OrderHistoryCubit>.value(
        value: orderHistoryCubit,
        child: const MaterialApp(home: OrdersView(useDemoOrders: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.loadCount, 2);
  });

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

  testWidgets('localizes order month names in Arabic', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final orderHistoryCubit = OrderHistoryCubit(
      GetMyOrdersUseCase(
        _OrderRepositoryWithData([_orderPlacedAt(DateTime(2026, 7, 14))]),
      ),
    );
    addTearDown(orderHistoryCubit.close);

    await tester.pumpWidget(
      BlocProvider<OrderHistoryCubit>.value(
        value: orderHistoryCubit,
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppTranslations.supportedLocales,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: OrdersView(useDemoOrders: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('14 يوليو 2026'), findsOneWidget);
    expect(find.text('14 Jul 2026'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows picked-up orders, shipping date, and market status in Arabic',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final item = const OrderItemData(
        id: 'item-1',
        productId: 'product-1',
        image: '',
        brand: 'Yalla',
        title: 'Test product',
        unitPrice: 75,
        quantity: 1,
      );
      final orderHistoryCubit = OrderHistoryCubit(
        GetMyOrdersUseCase(
          _OrderRepositoryWithData([
            _orderPlacedAt(
              DateTime(2026, 7, 14),
              status: OrderStatus.shipped,
              estimatedDeliveryAt: DateTime(2026, 7, 14, 12, 24),
              marketSections: [
                OrderMarketSectionData(
                  marketId: '1',
                  marketName: 'هوب شكلوب',
                  pickupStatus: 'picked_up',
                  subtotal: 75,
                  items: [item],
                ),
              ],
            ),
          ]),
        ),
      );
      addTearDown(orderHistoryCubit.close);

      await tester.pumpWidget(
        BlocProvider<OrderHistoryCubit>.value(
          value: orderHistoryCubit,
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppTranslations.supportedLocales,
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: OrdersView(useDemoOrders: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('في الطريق'), findsNWidgets(2));
      expect(find.text('14 يوليو 2026'), findsNWidgets(2));
      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();

      expect(find.text('تم الاستلام'), findsOneWidget);
      expect(find.text('picked_up'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

OrderData _orderPlacedAt(
  DateTime placedAt, {
  OrderStatus status = OrderStatus.pending,
  DateTime? estimatedDeliveryAt,
  List<OrderMarketSectionData> marketSections = const [],
}) {
  return OrderData(
    id: '6',
    orderNumber: '6',
    status: status,
    placedAt: placedAt,
    shippingAddress: const ShippingAddressData(
      fullName: 'Test Client',
      phone: '+201000000000',
      line1: 'Cairo',
      city: 'Cairo',
      state: 'Cairo',
      country: 'Egypt',
      postalCode: '',
    ),
    paymentMethod: 'cash',
    items: const [
      OrderItemData(
        id: 'item-1',
        productId: 'product-1',
        image: '',
        brand: 'Yalla',
        title: 'Test product',
        unitPrice: 75,
        quantity: 1,
      ),
    ],
    subtotal: 75,
    shippingFee: 0,
    taxTotal: 0,
    discountTotal: 0,
    total: 75,
    estimatedDeliveryAt: estimatedDeliveryAt,
    marketSections: marketSections,
  );
}

class _EmptyOrderRepository implements OrderRepository {
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
    return const ApiResult.success([]);
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

class _OrderRepositoryWithData extends _EmptyOrderRepository {
  _OrderRepositoryWithData(this.orders);

  final List<OrderData> orders;
  int loadCount = 0;

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    loadCount += 1;
    return ApiResult.success(orders);
  }
}
