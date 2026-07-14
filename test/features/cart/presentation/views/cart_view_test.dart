import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/cart/presentation/views/cart_view.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  testWidgets('shows selected variant attributes in cart items', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cartCubit = makeCartCubit();
    addTearDown(cartCubit.close);

    await cartCubit.loadCartForUser('user-a');
    await cartCubit.addItem(
      const CartItemData(
        id: 'variant_2',
        productId: 'product_1',
        variantId: 'variant_2',
        marketId: 'market_1',
        marketName: 'Yalla',
        image: AppAssets.temporaryMarketPlaceholder,
        brand: 'Yalla',
        title: 'شوربة خضار',
        price: 735,
        quantity: 2,
        attributes: [CartItemAttribute(label: 'الحصة', value: 'عائلية')],
      ),
      2,
    );

    await tester.pumpWidget(
      BlocProvider<CartCubit>.value(
        value: cartCubit,
        child: const MaterialApp(home: CartView()),
      ),
    );

    expect(find.text('شوربة خضار'), findsOneWidget);
    expect(find.textContaining('الحصة', findRichText: true), findsOneWidget);
    expect(find.textContaining('عائلية', findRichText: true), findsOneWidget);
    expect(find.textContaining('SEED-07-2', findRichText: true), findsNothing);
    expect(find.textContaining('1470', findRichText: true), findsWidgets);
  });

  testWidgets('shows all package products together as one offer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cartCubit = makeCartCubit();
    addTearDown(cartCubit.close);

    await cartCubit.loadCartForUser('user-a');
    await cartCubit.addItem(
      const CartItemData(
        id: '2',
        productId: '2',
        image: AppAssets.temporaryMarketPlaceholder,
        brand: 'Package offer',
        title: 'Sharm offer',
        price: 78.2,
        quantity: 1,
        itemType: 'offer',
        offerProducts: [
          CartOfferProductData(
            image: AppAssets.temporaryMarketPlaceholder,
            brand: 'Grocery Store',
            title: 'Chips',
            price: 20,
            quantity: 1,
          ),
          CartOfferProductData(
            image: AppAssets.temporaryMarketPlaceholder,
            brand: 'Dessert Store',
            title: 'Harissa',
            price: 72,
            quantity: 1,
          ),
        ],
      ),
      1,
    );

    await tester.pumpWidget(
      BlocProvider<CartCubit>.value(
        value: cartCubit,
        child: const MaterialApp(home: CartView()),
      ),
    );

    expect(find.text('Sharm offer'), findsOneWidget);
    expect(find.text('Chips'), findsOneWidget);
    expect(find.text('Harissa'), findsOneWidget);
    expect(find.text('2 products'), findsNWidgets(2));
    expect(find.text('Offer price'), findsOneWidget);
    expect(find.textContaining('78.2', findRichText: true), findsWidgets);
  });
}
