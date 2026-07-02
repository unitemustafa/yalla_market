import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/personalization/presentation/cubit/address_cubit.dart';
import 'package:yalla_market/features/store/data/repositories/order_repository_impl.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';
import 'package:yalla_market/features/store/presentation/cubit/checkout_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/checkout_view.dart';

import '../../../../helpers/cubit_factories.dart';
import '../../../../helpers/domain_fixtures.dart';

void main() {
  testWidgets('renders checkout summary without creating a real order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = OrderRepositoryImpl();
    final cartCubit = makeCartCubit();
    final addressCubit = makeAddressCubit();
    final checkoutCubit = makeCheckoutCubit(repository: orderRepository);
    final orderHistoryCubit = makeOrderHistoryCubit(
      repository: orderRepository,
    );
    await cartCubit.loadCartForUser('user-a');
    await cartCubit.addItem(
      sampleCartItem.copyWith(variantId: 'variant_1'),
      sampleCartItem.quantity,
    );
    addTearDown(cartCubit.close);
    addTearDown(addressCubit.close);
    addTearDown(checkoutCubit.close);
    addTearDown(orderHistoryCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<AddressCubit>.value(value: addressCubit),
          BlocProvider<CheckoutCubit>.value(value: checkoutCubit),
          BlocProvider<OrderHistoryCubit>.value(value: orderHistoryCubit),
        ],
        child: MaterialApp(
          routes: {
            AppRoutes.processingOrder: (_) =>
                const Scaffold(body: Text('processing order')),
          },
          home: const CheckoutView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order Review'), findsOneWidget);
    expect(find.text('Order Summary'), findsOneWidget);
    expect(find.text('Cash on Delivery'), findsOneWidget);
    expect(find.text('Shipping Address'), findsOneWidget);
    expect(find.text('Coding with T'), findsOneWidget);
    expect(find.text('Confirm Order'), findsOneWidget);

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(find.text('Order preview ready'), findsOneWidget);
    expect(find.text('processing order'), findsNothing);
    expect(cartCubit.state, isNotEmpty);
  });

  testWidgets('blocks checkout when cart items are missing variant ids', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = OrderRepositoryImpl();
    final cartCubit = makeCartCubit();
    final addressCubit = makeAddressCubit();
    final checkoutCubit = makeCheckoutCubit(repository: orderRepository);
    final orderHistoryCubit = makeOrderHistoryCubit(
      repository: orderRepository,
    );
    await cartCubit.loadCartForUser('user-a');
    await cartCubit.addItem(sampleCartItem, sampleCartItem.quantity);
    addTearDown(cartCubit.close);
    addTearDown(addressCubit.close);
    addTearDown(checkoutCubit.close);
    addTearDown(orderHistoryCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<AddressCubit>.value(value: addressCubit),
          BlocProvider<CheckoutCubit>.value(value: checkoutCubit),
          BlocProvider<OrderHistoryCubit>.value(value: orderHistoryCubit),
        ],
        child: MaterialApp(
          routes: {
            AppRoutes.processingOrder: (_) =>
                const Scaffold(body: Text('processing order')),
          },
          home: const CheckoutView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Order'));
    await tester.pump();

    expect(
      find.text(
        'Some cart items are missing variant information. Please add them again.',
      ),
      findsOneWidget,
    );
    expect(find.text('processing order'), findsNothing);
    expect(cartCubit.state, isNotEmpty);
  });

  testWidgets('confirm success clears cart and opens processing order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = _CreateOrderRepository();
    final cartCubit = makeCartCubit();
    final addressCubit = makeAddressCubit();
    final checkoutCubit = makeCheckoutCubit(repository: orderRepository);
    final orderHistoryCubit = makeOrderHistoryCubit(
      repository: orderRepository,
    );
    await cartCubit.loadCartForUser('user-a');
    await cartCubit.addItem(
      sampleCartItem.copyWith(variantId: '23'),
      sampleCartItem.quantity,
    );
    addTearDown(cartCubit.close);
    addTearDown(addressCubit.close);
    addTearDown(checkoutCubit.close);
    addTearDown(orderHistoryCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<AddressCubit>.value(value: addressCubit),
          BlocProvider<CheckoutCubit>.value(value: checkoutCubit),
          BlocProvider<OrderHistoryCubit>.value(value: orderHistoryCubit),
        ],
        child: MaterialApp(
          routes: {
            AppRoutes.processingOrder: (_) =>
                const Scaffold(body: Text('processing order')),
          },
          home: const CheckoutView(useDemoRepositories: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(orderRepository.createCalls, 1);
    expect(orderRepository.lastCartItems, hasLength(1));
    expect(cartCubit.state, isEmpty);
    expect(find.text('processing order'), findsOneWidget);
  });

  testWidgets('confirm failure keeps cart and shows error', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = _CreateOrderRepository(
      failure: const ServerFailure('Create order failed.'),
    );
    final cartCubit = makeCartCubit();
    final addressCubit = makeAddressCubit();
    final checkoutCubit = makeCheckoutCubit(repository: orderRepository);
    final orderHistoryCubit = makeOrderHistoryCubit(
      repository: orderRepository,
    );
    await cartCubit.loadCartForUser('user-a');
    await cartCubit.addItem(
      sampleCartItem.copyWith(variantId: '23'),
      sampleCartItem.quantity,
    );
    addTearDown(cartCubit.close);
    addTearDown(addressCubit.close);
    addTearDown(checkoutCubit.close);
    addTearDown(orderHistoryCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<AddressCubit>.value(value: addressCubit),
          BlocProvider<CheckoutCubit>.value(value: checkoutCubit),
          BlocProvider<OrderHistoryCubit>.value(value: orderHistoryCubit),
        ],
        child: MaterialApp(
          routes: {
            AppRoutes.processingOrder: (_) =>
                const Scaffold(body: Text('processing order')),
          },
          home: const CheckoutView(useDemoRepositories: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(orderRepository.createCalls, 1);
    expect(find.text('Create order failed.'), findsOneWidget);
    expect(find.text('processing order'), findsNothing);
    expect(cartCubit.state, isNotEmpty);
  });
}

class _CreateOrderRepository implements OrderRepository {
  _CreateOrderRepository({this.failure});

  final Failure? failure;
  int createCalls = 0;
  List<CartItemData> lastCartItems = const [];

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
    createCalls += 1;
    lastCartItems = cartItems;
    if (failure case final failure?) {
      return ApiResult.failure(failure);
    }
    return ApiResult.success(sampleOrder);
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    return ApiResult.success([sampleOrder]);
  }

  @override
  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
  }) async {
    return const ApiResult.success(
      OrderPreviewData(
        summary: OrderPreviewSummaryData(
          subtotal: 1200,
          discountTotal: 0,
          deliveryTotal: 50,
          grandTotal: 1250,
        ),
      ),
    );
  }
}
