import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/core/presentation/widgets/texts/green_currency_price.dart';
import 'package:yalla_market/core/routing/app_route_arguments.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  testWidgets('passes the backend product ID when a product card is opened', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cartCubit = makeCartCubit();
    final wishlistCubit = makeWishlistCubit();
    await cartCubit.loadCartForUser('product-card-user');
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);
    ProductDetailRouteArgs? capturedArgs;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.productDetail) {
              capturedArgs = settings.arguments as ProductDetailRouteArgs;
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Details route')),
                settings: settings,
              );
            }
            return null;
          },
          home: const Scaffold(
            body: SizedBox(
              width: 220,
              height: 220,
              child: ProductCardVertical(
                productId: 'backend-product-42',
                image: AppAssets.defaultProduct,
                title: 'Backend product',
                brand: 'Backend market',
                price: '120.00',
              ),
            ),
          ),
        ),
      ),
    );

    final addButton = find.byKey(
      const ValueKey('product_add_to_cart_backend-product-42'),
    );
    final buttonRectBefore = tester.getRect(addButton);
    await tester.tap(addButton);
    await tester.pump();
    expect(tester.getRect(addButton), buttonRectBefore);
    expect(
      find.descendant(of: addButton, matching: find.text('Add to cart')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: addButton,
        matching: find.byKey(const ValueKey('cart_quantity_1')),
      ),
      findsOneWidget,
    );
    await tester.tap(addButton);
    await tester.pump();
    expect(
      find.descendant(
        of: addButton,
        matching: find.byKey(const ValueKey('cart_quantity_2')),
      ),
      findsOneWidget,
    );
    final marketRect = tester.getRect(find.text('Backend market'));
    final priceRect = tester.getRect(find.byType(GreenCurrencyPrice));
    final productRect = tester.getRect(find.byType(ProductCardVertical));
    final titleRect = tester.getRect(find.text('Backend product'));
    expect(priceRect.top - marketRect.bottom, lessThanOrEqualTo(6));
    expect(buttonRectBefore.top - priceRect.bottom, lessThanOrEqualTo(8));
    expect(productRect.bottom - buttonRectBefore.bottom, lessThanOrEqualTo(8));
    expect(
      (titleRect.center.dx - productRect.center.dx).abs(),
      lessThanOrEqualTo(2),
    );
    expect(
      (priceRect.center.dx - productRect.center.dx).abs(),
      lessThanOrEqualTo(2),
    );

    await tester.tap(find.text('Backend product'));
    await tester.pumpAndSettle();

    expect(find.text('Details route'), findsOneWidget);
    expect(capturedArgs?.productId, 'backend-product-42');
  });

  testWidgets('shows discounted variant range and Arabic discount label', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cartCubit = makeCartCubit();
    final wishlistCubit = makeWishlistCubit();
    await cartCubit.loadCartForUser('discount-card-user');
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar'), Locale('en')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 360,
              child: ProductCardVertical(
                productId: 'discounted-product',
                image: AppAssets.defaultProduct,
                title: 'منتج',
                brand: 'محل',
                price: '100.00 ~ 200.00',
                discount: '50.00',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('خصم 50%'), findsOneWidget);
    final discountText = tester.widget<Text>(find.text('خصم 50%'));
    expect(discountText.style?.fontSize, AppFontSizes.micro);
    final discountBadge = tester.widget<Container>(
      find.byKey(const ValueKey('product_discount_badge_discounted-product')),
    );
    expect(
      discountBadge.padding,
      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
    expect(tester.widget<AppImage>(find.byType(AppImage)).fit, BoxFit.cover);
    final priceTexts = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((widget) => widget.text.toPlainText());
    expect(priceTexts.any((text) => text.contains('50 - 100')), isTrue);
  });

  testWidgets('fits a compact discounted card on an iPhone SE width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final cartCubit = makeCartCubit();
    final wishlistCubit = makeWishlistCubit();
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.3),
            ),
            child: const Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 142,
                  height: 220,
                  child: ProductCardVertical(
                    productId: 'iphone-product',
                    image: AppAssets.defaultProduct,
                    title: 'A very long product name for a narrow phone',
                    brand: 'A very long market name',
                    price: '120.00',
                    oldPrice: '180.00',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final cardRect = tester.getRect(find.byType(ProductCardVertical));
    final addButtonRect = tester.getRect(
      find.byKey(const ValueKey('product_add_to_cart_iphone-product')),
    );
    expect(addButtonRect.height, 34);
    expect(cardRect.bottom - addButtonRect.bottom, lessThanOrEqualTo(8));
    expect(tester.takeException(), isNull);
  });
}
