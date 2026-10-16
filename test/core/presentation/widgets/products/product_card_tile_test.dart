import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_card_tile.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_results_view.dart'
    show productCardTileData;
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  const first = ProductData(
    id: 'first',
    image: AppAssets.defaultProduct,
    title: 'First product',
    brand: 'Market',
    price: '10',
    oldPrice: null,
    discount: '',
    tags: [],
  );
  const second = ProductData(
    id: 'second',
    image: AppAssets.defaultProduct,
    title: 'Second product',
    brand: 'Market',
    price: '20',
    oldPrice: null,
    discount: '',
    tags: [],
  );

  Future<void> mount(
    WidgetTester tester, {
    required ValueNotifier<List<ProductData>> products,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final cart = makeCartCubit();
    final wishlist = makeWishlistCubit();
    await cart.loadCartForUser('tile-test-user');
    await wishlist.loadWishlistForUser('tile-test-user');
    addTearDown(cart.close);
    addTearDown(wishlist.close);
    addTearDown(products.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cart),
          BlocProvider<WishlistCubit>.value(value: wishlist),
        ],
        child: MaterialApp(
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: ValueListenableBuilder<List<ProductData>>(
              valueListenable: products,
              builder: (context, items, _) => Column(
                children: [
                  for (final product in items)
                    SizedBox(
                      key: ValueKey('slot_${product.id}'),
                      width: 180,
                      height: 188,
                      child: ProductCardTile(
                        key: ValueKey(product.id),
                        product: productCardTileData(product),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder card(String id) => find.byWidgetPredicate(
    (widget) => widget is ProductCardVertical && widget.productId == id,
  );

  testWidgets(
    'Given unchanged render inputs when the parent rebuilds then it retains the card widget',
    (tester) async {
      final products = ValueNotifier<List<ProductData>>([first]);
      await mount(tester, products: products);
      final before = tester.widget<ProductCardVertical>(card('first'));

      products.value = [first];
      await tester.pump();

      expect(tester.widget<ProductCardVertical>(card('first')), same(before));
      expect(find.text('First product'), findsOneWidget);
    },
  );

  testWidgets(
    'Given a product update when a render property changes then it replaces only that card widget',
    (tester) async {
      final products = ValueNotifier<List<ProductData>>([first, second]);
      await mount(tester, products: products);
      final unchanged = tester.widget<ProductCardVertical>(card('second'));
      final before = tester.widget<ProductCardVertical>(card('first'));
      const updated = ProductData(
        id: 'first',
        image: AppAssets.defaultProduct,
        title: 'Updated first product',
        brand: 'Market',
        price: '15',
        oldPrice: null,
        discount: '',
        tags: [],
      );

      products.value = [updated, second];
      await tester.pump();

      expect(
        tester.widget<ProductCardVertical>(card('first')),
        isNot(same(before)),
      );
      expect(
        tester.widget<ProductCardVertical>(card('second')),
        same(unchanged),
      );
      expect(find.text('Updated first product'), findsOneWidget);
    },
  );

  testWidgets(
    'Given keyed products when they reorder and one is removed then each remaining card keeps its mapping',
    (tester) async {
      final products = ValueNotifier<List<ProductData>>([first, second]);
      await mount(tester, products: products);
      final firstElement = tester.element(card('first'));
      final secondElement = tester.element(card('second'));

      products.value = [second, first];
      await tester.pump();
      expect(tester.element(card('first')), same(firstElement));
      expect(tester.element(card('second')), same(secondElement));

      products.value = [first];
      await tester.pump();
      expect(tester.element(card('first')), same(firstElement));
      expect(card('second'), findsNothing);
    },
  );

  testWidgets(
    'Given a retained tile when its cart action is tapped then its local listener remains active',
    (tester) async {
      final products = ValueNotifier<List<ProductData>>([first]);
      await mount(tester, products: products);
      products.value = [first];
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('product_add_to_cart_first')));
      await tester.pump();

      expect(find.byKey(const ValueKey('cart_quantity_1')), findsOneWidget);
    },
  );

  testWidgets(
    'Given a retained tile when theme and locale change then its product label remains visible',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final cart = makeCartCubit();
      final wishlist = makeWishlistCubit();
      final appearance = ValueNotifier<(ThemeData, Locale)>((
        ThemeData.light(),
        const Locale('en'),
      ));
      await cart.loadCartForUser('tile-appearance-user');
      await wishlist.loadWishlistForUser('tile-appearance-user');
      addTearDown(cart.close);
      addTearDown(wishlist.close);
      addTearDown(appearance.dispose);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cart),
            BlocProvider<WishlistCubit>.value(value: wishlist),
          ],
          child: ValueListenableBuilder<(ThemeData, Locale)>(
            valueListenable: appearance,
            builder: (context, value, _) => MaterialApp(
              theme: value.$1,
              locale: value.$2,
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Scaffold(
                body: SizedBox(
                  width: 180,
                  height: 188,
                  child: ProductCardTile(product: productCardTileData(first)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = tester.widget<ProductCardVertical>(card('first'));

      appearance.value = (ThemeData.dark(), const Locale('ar'));
      await tester.pumpAndSettle();

      expect(tester.widget<ProductCardVertical>(card('first')), same(before));
      expect(find.text('First product'), findsOneWidget);
    },
  );
}
