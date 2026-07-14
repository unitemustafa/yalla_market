import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/constants/app_colors.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/location/domain/repositories/location_repository.dart';
import 'package:yalla_market/features/location/domain/usecases/location_usecases.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
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
    expect(find.text('payment success'), findsNothing);
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
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
    expect(find.text('payment success'), findsNothing);
    expect(cartCubit.state, isNotEmpty);
  });

  testWidgets('confirm success clears cart and opens payment success', (
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(orderRepository.createCalls, 1);
    expect(orderRepository.getMyOrdersCalls, 1);
    expect(orderRepository.lastCartItems, hasLength(1));
    expect(cartCubit.state, isEmpty);
    expect(find.text('payment success'), findsOneWidget);
  });

  testWidgets('missing region opens selection and does not create order', (
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      selectedCity: null,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(orderRepository.createCalls, 0);
    expect(find.text('select city'), findsOneWidget);
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(orderRepository.createCalls, 1);
    expect(orderRepository.getMyOrdersCalls, 0);
    expect(find.text('Create order failed.'), findsOneWidget);
    expect(find.text('payment success'), findsNothing);
    expect(cartCubit.state, isNotEmpty);
  });

  testWidgets('fixed-area preview shows simplified summary', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = _CreateOrderRepository(
      preview: _twoMarketFixedAreaPreview(),
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Market breakdown'), findsNothing);
    expect(find.text('Fresh Market'), findsNothing);
    expect(find.text('Daily Market'), findsNothing);
    expect(find.text('Delivery type'), findsNothing);
    expect(find.text('Fixed-price delivery'), findsNothing);
    expect(find.text('Delivery - price determined later'), findsNothing);
    expect(_findPlainText('EGP 120'), findsOneWidget);
    expect(find.text('+ Delivery'), findsOneWidget);
    expect(_findTextWithColor('+ Delivery', AppColors.error), findsOneWidget);
    expect(_findPlainText('EGP 1580'), findsWidgets);
    expect(_findPlainText('EGP 1580.00'), findsNothing);
  });

  testWidgets('pending delivery preview shows compact shipping and total', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = _CreateOrderRepository(
      preview: _twoMarketPendingDeliveryPreview(),
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Market breakdown'), findsNothing);
    expect(find.text('Fresh Market'), findsNothing);
    expect(find.text('Daily Market'), findsNothing);
    expect(find.text('Delivery type'), findsNothing);
    expect(find.text('Delivery - price determined later'), findsNothing);
    expect(find.text('Determined later'), findsNothing);
    expect(find.text('Not specified'), findsOneWidget);
    expect(
      _findTextWithColor('Not specified', AppColors.error),
      findsOneWidget,
    );
    expect(find.text('Courier'), findsNothing);
    expect(_findPlainText('EGP 1700'), findsOneWidget);
    expect(_findPlainText('EGP 1460'), findsNWidgets(2));
    expect(find.text('+ Courier'), findsOneWidget);
    expect(_findTextWithColor('+ Courier', AppColors.error), findsOneWidget);
    expect(_findPlainText('EGP 1460.00 + delivery fee'), findsNothing);
    expect(find.textContaining('delivery fee'), findsNothing);
  });

  testWidgets(
    'package offer review expands server-priced products and explains discount',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final orderRepository = _CreateOrderRepository(
        preview: _packageOfferPreview(),
      );
      final cartCubit = makeCartCubit();
      final addressCubit = makeAddressCubit();
      final checkoutCubit = makeCheckoutCubit(repository: orderRepository);
      final orderHistoryCubit = makeOrderHistoryCubit(
        repository: orderRepository,
      );
      await cartCubit.loadCartForUser('user-a');
      await cartCubit.addItem(
        const CartItemData(
          id: '2',
          productId: '2',
          image: 'chips.png',
          brand: 'Grocery Store',
          title: 'Chips',
          price: 85,
          quantity: 1,
          itemType: 'offer',
          attributes: [CartItemAttribute(label: 'Offer', value: 'Sharm offer')],
        ),
        1,
      );
      addTearDown(cartCubit.close);
      addTearDown(addressCubit.close);
      addTearDown(checkoutCubit.close);
      addTearDown(orderHistoryCubit.close);

      await _pumpCheckoutView(
        tester,
        cartCubit: cartCubit,
        addressCubit: addressCubit,
        checkoutCubit: checkoutCubit,
        orderHistoryCubit: orderHistoryCubit,
        checkoutView: const CheckoutView(useDemoRepositories: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 products'), findsOneWidget);
      expect(find.text('Chips'), findsOneWidget);
      expect(find.text('Harissa'), findsOneWidget);
      expect(find.text('Qty 1'), findsNWidgets(2));
      expect(_findPlainText('EGP 20'), findsOneWidget);
      expect(_findPlainText('EGP 72'), findsOneWidget);
      expect(_findPlainText('EGP 85'), findsNothing);
      expect(_findPlainText('EGP 92'), findsOneWidget);
      expect(find.text('Offer discount (15%)'), findsOneWidget);
      expect(_findPlainText('EGP 13.80'), findsOneWidget);

      final shippingValue = find.byKey(
        const ValueKey('summary-value-Delivery'),
      );
      expect(shippingValue, findsOneWidget);
      expect(
        find.descendant(of: shippingValue, matching: _findPlainText('EGP 600')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: shippingValue, matching: find.text('+ Delivery')),
        findsOneWidget,
      );
    },
  );

  testWidgets('checkout price formatting trims only empty decimals', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = _CreateOrderRepository(
      preview: _priceFormattingPreview(),
    );
    final cartCubit = makeCartCubit();
    final addressCubit = makeAddressCubit();
    final checkoutCubit = makeCheckoutCubit(repository: orderRepository);
    final orderHistoryCubit = makeOrderHistoryCubit(
      repository: orderRepository,
    );
    await cartCubit.loadCartForUser('user-a');
    await cartCubit.addItem(
      sampleCartItem.copyWith(price: 10.5, variantId: '23'),
      sampleCartItem.quantity,
    );
    addTearDown(cartCubit.close);
    addTearDown(addressCubit.close);
    addTearDown(checkoutCubit.close);
    addTearDown(orderHistoryCubit.close);

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    expect(_findPlainText('EGP 10.50'), findsNWidgets(2));
    expect(_findPlainText('EGP 1050'), findsWidgets);
    expect(_findPlainText('EGP 1050.00'), findsNothing);
  });

  testWidgets('pending delivery fee does not disable confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = _CreateOrderRepository(
      preview: _twoMarketPendingDeliveryPreview(),
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(orderRepository.createCalls, 1);
    expect(find.text('payment success'), findsOneWidget);
  });

  testWidgets('bottom bar renders pending and fixed totals without ellipsis', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final pendingRepository = _CreateOrderRepository(
      preview: _twoMarketPendingDeliveryPreview(),
    );
    final cartCubit = makeCartCubit();
    final addressCubit = makeAddressCubit();
    final checkoutCubit = makeCheckoutCubit(repository: pendingRepository);
    final orderHistoryCubit = makeOrderHistoryCubit(
      repository: pendingRepository,
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    expect(_findPlainText('EGP 1460'), findsNWidgets(2));
    expect(find.text('+ Courier'), findsOneWidget);
    expect(
      _findTextWithOverflow('EGP 1460', TextOverflow.ellipsis),
      findsNothing,
    );
    expect(
      _findTextWithOverflow('+ Courier', TextOverflow.ellipsis),
      findsNothing,
    );
    expect(
      _findTextWithOverflow('EGP 1460', TextOverflow.visible),
      findsNothing,
    );
    expect(
      _findTextWithOverflow('+ Courier', TextOverflow.visible),
      findsNothing,
    );

    final fixedRepository = _CreateOrderRepository(
      preview: _twoMarketFixedAreaPreview(),
    );
    final fixedCheckoutCubit = makeCheckoutCubit(repository: fixedRepository);
    final fixedOrderHistoryCubit = makeOrderHistoryCubit(
      repository: fixedRepository,
    );
    addTearDown(fixedCheckoutCubit.close);
    addTearDown(fixedOrderHistoryCubit.close);

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: fixedCheckoutCubit,
      orderHistoryCubit: fixedOrderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    expect(_findPlainText('EGP 1200'), findsWidgets);
    expect(find.text('+ Courier'), findsNothing);
  });

  testWidgets('bottom bar fits pending delivery at narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final orderRepository = _CreateOrderRepository(
      preview: _twoMarketPendingDeliveryPreview(),
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_findPlainText('EGP 1460'), findsNWidgets(2));
    expect(find.text('+ Courier'), findsOneWidget);
    expect(find.text('Confirm Order'), findsOneWidget);
    expect(tester.getSize(find.text('Confirm Order')), isNot(Size.zero));

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(orderRepository.createCalls, 1);
    expect(find.text('payment success'), findsOneWidget);
  });

  testWidgets('pending delivery plus sign stays leading in Arabic', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = _CreateOrderRepository(
      preview: _twoMarketPendingDeliveryPreview(),
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
      locale: const Locale('ar'),
    );
    await tester.pumpAndSettle();

    expect(find.text('+ دليفيري'), findsOneWidget);
    expect(find.text('دليفيري +'), findsNothing);
    expect(
      _findTextWithDirection('+ دليفيري', TextDirection.ltr),
      findsOneWidget,
    );
  });

  testWidgets('hides selection chips and pins the total to the outer edge', (
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
      locale: const Locale('ar'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selected'), findsNothing);
    expect(find.text('Default'), findsNothing);
    expect(find.text('مختار'), findsNothing);
    expect(find.text('الافتراضي'), findsNothing);

    final panelRect = tester.getRect(
      find.byKey(const ValueKey('order-total-panel')),
    );
    final labelRect = tester.getRect(
      find.byKey(const ValueKey('order-total-label')),
    );
    final valueRect = tester.getRect(
      find.byKey(const ValueKey('order-total-value')),
    );
    expect(panelRect.right - labelRect.right, lessThanOrEqualTo(16));
    expect(valueRect.left - panelRect.left, lessThanOrEqualTo(16));
  });

  testWidgets('delivery unavailable blocks confirmation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = _CreateOrderRepository(
      preview: _twoMarketPendingDeliveryPreview(deliveryAvailable: false),
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'التوصيل غير متاح لأحد المحلات في سلتك. راجع مدينة عنوان التوصيل أو احذف المحل غير المتاح.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(orderRepository.createCalls, 0);
    expect(cartCubit.state, isNotEmpty);
  });

  testWidgets('preview failure keeps cart and blocks confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final orderRepository = _CreateOrderRepository(
      previewFailure: const ServerFailure('Preview failed.'),
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

    await _pumpCheckoutView(
      tester,
      cartCubit: cartCubit,
      addressCubit: addressCubit,
      checkoutCubit: checkoutCubit,
      orderHistoryCubit: orderHistoryCubit,
      checkoutView: const CheckoutView(useDemoRepositories: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(orderRepository.createCalls, 0);
    expect(
      find.text('Could not refresh order totals. Try again.'),
      findsWidgets,
    );
    expect(cartCubit.state, isNotEmpty);
    expect(find.text('payment success'), findsNothing);
  });
}

Future<void> _pumpCheckoutView(
  WidgetTester tester, {
  required CartCubit cartCubit,
  required AddressCubit addressCubit,
  required CheckoutCubit checkoutCubit,
  required OrderHistoryCubit orderHistoryCubit,
  CityData? selectedCity = CityData.general,
  CheckoutView checkoutView = const CheckoutView(),
  Locale locale = const Locale('en'),
}) async {
  final locationCubit = LocationCubit(
    _locationUseCases(_FakeLocationRepository(selectedCity: selectedCity)),
  );
  await locationCubit.loadSelectedCity();
  addTearDown(locationCubit.close);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>.value(value: cartCubit),
        BlocProvider<AddressCubit>.value(value: addressCubit),
        BlocProvider<LocationCubit>.value(value: locationCubit),
        BlocProvider<CheckoutCubit>.value(value: checkoutCubit),
        BlocProvider<OrderHistoryCubit>.value(value: orderHistoryCubit),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppTranslations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routes: {
          AppRoutes.processingOrder: (_) =>
              const Scaffold(body: Text('processing order')),
          AppRoutes.paymentSuccess: (_) =>
              const Scaffold(body: Text('payment success')),
          AppRoutes.selectCity: (_) =>
              const Scaffold(body: Text('select city')),
        },
        home: checkoutView,
      ),
    ),
  );
}

LocationUseCases _locationUseCases(_FakeLocationRepository repository) {
  return LocationUseCases(
    activateUser: ActivateLocationUserUseCase(repository),
    getAvailableCities: GetAvailableCitiesUseCase(repository),
    getSelectedCity: GetSelectedCityUseCase(repository),
    hasSeenCitySelection: HasSeenCitySelectionUseCase(repository),
    markCitySelectionSeen: MarkCitySelectionSeenUseCase(repository),
    clearSelectedCity: ClearSelectedCityUseCase(repository),
    saveSelectedCity: SaveSelectedCityUseCase(repository),
    detectCurrentLocation: DetectCurrentLocationUseCase(repository),
    detectMarketRegion: DetectMarketRegionUseCase(repository),
    useCurrentLocation: UseCurrentLocationUseCase(repository),
    openAppSettings: OpenLocationAppSettingsUseCase(repository),
    openLocationSettings: OpenDeviceLocationSettingsUseCase(repository),
  );
}

Finder _findPlainText(String text) {
  String normalize(String value) => value.replaceAll('\u00A0', ' ');

  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    return normalize(widget.data ?? '') == text ||
        normalize(widget.textSpan?.toPlainText() ?? '') == text;
  });
}

Finder _findTextWithColor(String text, Color color) {
  String normalize(String value) => value.replaceAll('\u00A0', ' ');

  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    final plainText = normalize(
      widget.data ?? widget.textSpan?.toPlainText() ?? '',
    );
    return plainText == text && widget.style?.color == color;
  });
}

Finder _findTextWithOverflow(String text, TextOverflow overflow) {
  String normalize(String value) => value.replaceAll('\u00A0', ' ');

  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    final plainText = normalize(
      widget.data ?? widget.textSpan?.toPlainText() ?? '',
    );
    return plainText == text && widget.overflow == overflow;
  });
}

Finder _findTextWithDirection(String text, TextDirection direction) {
  String normalize(String value) => value.replaceAll('\u00A0', ' ');

  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    final plainText = normalize(
      widget.data ?? widget.textSpan?.toPlainText() ?? '',
    );
    return plainText == text && widget.textDirection == direction;
  });
}

class _FakeLocationRepository implements LocationRepository, LocationUserScope {
  const _FakeLocationRepository({required this.selectedCity});

  final CityData? selectedCity;

  @override
  Future<ApiResult<void>> activateUser(String userId) async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> clearSelectedCity() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<CityData>> detectCurrentLocation({
    bool requestPermission = true,
  }) async {
    return ApiResult.success(selectedCity ?? CityData.general);
  }

  Future<ApiResult<GpsRegionDetection>> detectMarketRegion() async {
    return const ApiResult.success(
      GpsRegionDetection(
        action: GpsRegionAction.sameRegion,
        currentSelection: null,
        detectedRegion: null,
        message: '',
      ),
    );
  }

  @override
  Future<ApiResult<List<CityData>>> getAvailableCities() async {
    final city = selectedCity;
    return ApiResult.success(city == null ? [CityData.general] : [city]);
  }

  @override
  Future<ApiResult<CityData?>> getSelectedCity() async {
    return ApiResult.success(selectedCity);
  }

  @override
  Future<ApiResult<bool>> hasSeenCitySelection() async {
    return const ApiResult.success(false);
  }

  @override
  Future<ApiResult<void>> markCitySelectionSeen() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> openAppSettings() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> openLocationSettings() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<CityData>> saveSelectedCity(CityData city) async {
    return ApiResult.success(city);
  }

  @override
  Future<ApiResult<CityData>> useCurrentLocation() async {
    return ApiResult.success(selectedCity ?? CityData.general);
  }
}

class _CreateOrderRepository implements OrderRepository {
  _CreateOrderRepository({this.failure, this.preview, this.previewFailure});

  final Failure? failure;
  final OrderPreviewData? preview;
  final Failure? previewFailure;
  int createCalls = 0;
  int getMyOrdersCalls = 0;
  List<CartItemData> lastCartItems = const [];

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
    createCalls += 1;
    lastCartItems = cartItems;
    if (failure case final failure?) {
      return ApiResult.failure(failure);
    }
    return ApiResult.success([sampleOrder]);
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    getMyOrdersCalls += 1;
    return ApiResult.success([sampleOrder]);
  }

  @override
  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
    required String addressId,
    String? paymentMethod,
    String? description,
    String? deliveryNote,
  }) async {
    if (previewFailure case final failure?) {
      return ApiResult.failure(failure);
    }
    return ApiResult.success(
      preview ??
          const OrderPreviewData(
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

OrderPreviewData _priceFormattingPreview() {
  return const OrderPreviewData(
    marketGroups: [
      OrderPreviewMarketGroupData(
        deliveryType: 'fixed_area',
        deliveryPrice: 1039.5,
        deliveryAvailable: true,
        pricing: OrderPreviewPricingData(
          productsSubtotal: 10.5,
          totalOfferDiscounts: 0,
          deliveryPrice: 1039.5,
          marketTotal: 1050,
        ),
      ),
    ],
    summary: OrderPreviewSummaryData(
      subtotal: 10.5,
      discountTotal: 0,
      deliveryTotal: 1039.5,
      grandTotal: 1050,
    ),
  );
}

OrderPreviewData _twoMarketFixedAreaPreview() {
  return OrderPreviewData(
    serviceCity: const {'id': 1, 'name': 'Cairo'},
    orderScope: 'service_city',
    isMultiMarket: true,
    marketCount: 2,
    marketNamesSummary: 'Fresh Market, Daily Market',
    marketGroups: [
      const OrderPreviewMarketGroupData(
        market: {'id': 5, 'name': 'Fresh Market'},
        serviceCity: {'id': 1, 'name': 'Cairo'},
        deliveryArea: {'id': 2, 'name': 'Downtown'},
        deliveryType: 'fixed_area',
        deliveryPrice: 120,
        deliveryAvailable: true,
        selectedProducts: [
          {'id': 1, 'name': 'Tomatoes'},
        ],
        selectedOffers: [
          {'id': 3, 'name': 'Bundle'},
        ],
        pricing: OrderPreviewPricingData(
          productsSubtotal: 1000,
          totalOfferDiscounts: 100,
          deliveryPrice: 120,
          marketTotal: 1020,
        ),
      ),
      OrderPreviewMarketGroupData(
        market: const {'id': 8, 'name': 'Daily Market'},
        serviceCity: const {'id': 1, 'name': 'Cairo'},
        deliveryArea: const {'id': 2, 'name': 'Downtown'},
        deliveryType: 'fixed_area',
        deliveryPrice: null,
        deliveryAvailable: true,
        pricing: const OrderPreviewPricingData(
          productsSubtotal: 700,
          totalOfferDiscounts: 140,
          deliveryPrice: null,
          marketTotal: 560,
        ),
      ),
    ],
    summary: const OrderPreviewSummaryData(
      subtotal: 1700,
      discountTotal: 240,
      deliveryTotal: 120,
      grandTotal: 1580,
    ),
  );
}

OrderPreviewData _packageOfferPreview() {
  return const OrderPreviewData(
    marketGroups: [
      OrderPreviewMarketGroupData(
        market: {'id': 3, 'name': 'Grocery Store'},
        deliveryType: 'fixed_area',
        deliveryPrice: 600,
        deliveryAvailable: true,
        selectedOffers: [
          {
            'id': 2,
            'title': 'Sharm offer',
            'discount_percentage': '15.00',
            'offer_products_subtotal': '20.00',
            'discount_amount': '3.00',
            'products': [
              {
                'product_id': 7,
                'product_name': 'Chips',
                'image': 'chips.png',
                'variant_id': 12,
                'quantity': 1,
                'unit_price': '20.00',
                'subtotal': '20.00',
              },
            ],
          },
        ],
        pricing: OrderPreviewPricingData(
          productsSubtotal: 20,
          totalOfferDiscounts: 3,
          deliveryPrice: 600,
          marketTotal: 617,
        ),
      ),
      OrderPreviewMarketGroupData(
        market: {'id': 6, 'name': 'Dessert Store'},
        deliveryType: 'fixed_area',
        deliveryPrice: null,
        deliveryAvailable: true,
        selectedOffers: [
          {
            'id': 2,
            'title': 'Sharm offer',
            'discount_percentage': '15.00',
            'offer_products_subtotal': '72.00',
            'discount_amount': '10.80',
            'products': [
              {
                'product_id': 6,
                'product_name': 'Harissa',
                'image': 'harissa.png',
                'variant_id': 10,
                'quantity': 1,
                'unit_price': '72.00',
                'subtotal': '72.00',
              },
            ],
          },
        ],
        pricing: OrderPreviewPricingData(
          productsSubtotal: 72,
          totalOfferDiscounts: 10.8,
          deliveryPrice: null,
          marketTotal: 61.2,
        ),
      ),
    ],
    summary: OrderPreviewSummaryData(
      subtotal: 92,
      discountTotal: 13.8,
      deliveryTotal: 600,
      grandTotal: 678.2,
    ),
  );
}

OrderPreviewData _twoMarketPendingDeliveryPreview({
  bool deliveryAvailable = true,
}) {
  return OrderPreviewData(
    serviceCity: const {'id': 1, 'name': 'Cairo'},
    orderScope: 'service_city',
    isMultiMarket: true,
    marketCount: 2,
    marketNamesSummary: 'Fresh Market, Daily Market',
    marketGroups: [
      OrderPreviewMarketGroupData(
        market: const {'id': 5, 'name': 'Fresh Market'},
        serviceCity: const {'id': 1, 'name': 'Cairo'},
        deliveryArea: const {'id': 2, 'name': 'Downtown'},
        deliveryType: 'delivery',
        deliveryPrice: null,
        deliveryMessage: 'Delivery price will be determined later.',
        deliveryAvailable: deliveryAvailable,
        selectedProducts: const [
          {'id': 1, 'name': 'Tomatoes'},
        ],
        selectedOffers: const [
          {'id': 3, 'name': 'Bundle'},
        ],
        pricing: const OrderPreviewPricingData(
          productsSubtotal: 1000,
          totalOfferDiscounts: 100,
          deliveryPrice: null,
          marketTotal: 900,
        ),
      ),
      OrderPreviewMarketGroupData(
        market: const {'id': 8, 'name': 'Daily Market'},
        serviceCity: const {'id': 1, 'name': 'Cairo'},
        deliveryArea: const {'id': 2, 'name': 'Downtown'},
        deliveryType: 'delivery',
        deliveryPrice: null,
        deliveryMessage: 'Delivery price will be determined later.',
        deliveryAvailable: deliveryAvailable,
        pricing: const OrderPreviewPricingData(
          productsSubtotal: 700,
          totalOfferDiscounts: 140,
          deliveryPrice: null,
          marketTotal: 560,
        ),
      ),
    ],
    summary: const OrderPreviewSummaryData(
      subtotal: 1700,
      discountTotal: 240,
      deliveryTotal: 0,
      grandTotal: 1460,
    ),
  );
}
