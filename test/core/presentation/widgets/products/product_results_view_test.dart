import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_results_view.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  testWidgets('shows ten products per page by default', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final cartCubit = makeCartCubit();
    final wishlistCubit = makeWishlistCubit();
    await cartCubit.loadCartForUser('product-results-user');
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductResultsView(
                products: List.generate(11, _product),
                initialSortOption: 'Newest',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ProductCardVertical), findsNWidgets(10));
    expect(find.text('1/2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('product_add_to_cart_product-10')),
      findsNothing,
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1600),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.byType(ProductCardVertical), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('product_add_to_cart_product-10')),
      findsOneWidget,
    );
  });

  testWidgets(
    'store controls appear before subcategories and filter products',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final cartCubit = makeCartCubit();
      final wishlistCubit = makeWishlistCubit();
      await cartCubit.loadCartForUser('store-controls-user');
      addTearDown(cartCubit.close);
      addTearDown(wishlistCubit.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cartCubit),
            BlocProvider<WishlistCubit>.value(value: wishlistCubit),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProductResultsView(
                  products: [_product(0), _product(1)],
                  initialSortOption: 'Newest',
                  useHomeSearchStyle: true,
                  contentAfterSearch: const SizedBox(
                    key: ValueKey('test_offer_section'),
                    height: 80,
                  ),
                  controlsFooter: const SizedBox(
                    key: ValueKey('test_subcategory_rail'),
                    height: 94,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final search = find.byKey(const ValueKey('store_product_search_field'));
      final offers = find.byKey(const ValueKey('test_offer_section'));
      final categories = find.byKey(const ValueKey('test_subcategory_rail'));
      expect(search, findsOneWidget);
      expect(
        find.byKey(const ValueKey('store_product_filter_button')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(search).dy,
        lessThan(tester.getTopLeft(offers).dy),
      );
      expect(
        tester.getTopLeft(offers).dy,
        lessThan(tester.getTopLeft(categories).dy),
      );

      await tester.enterText(
        find.descendant(of: search, matching: find.byType(TextField)),
        'Product 1',
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('product_add_to_cart_product-0')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('product_add_to_cart_product-1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'keeps the query but dismisses focus when another route covers the page',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final cartCubit = makeCartCubit();
      final wishlistCubit = makeWishlistCubit();
      await cartCubit.loadCartForUser('store-focus-user');
      addTearDown(cartCubit.close);
      addTearDown(wishlistCubit.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cartCubit),
            BlocProvider<WishlistCubit>.value(value: wishlistCubit),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProductResultsView(
                products: [_product(0), _product(1)],
                useHomeSearchStyle: true,
              ),
            ),
          ),
        ),
      );

      final search = find.byKey(const ValueKey('store_product_search_field'));
      final textField = find.descendant(
        of: search,
        matching: find.byType(TextField),
      );
      await tester.tap(textField);
      await tester.enterText(textField, 'Product 1');
      await tester.pump();
      expect(tester.widget<TextField>(textField).focusNode?.hasFocus, isTrue);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Next page')),
        ),
      );
      await tester.pumpAndSettle();
      navigator.pop();
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(textField).controller?.text, 'Product 1');
      expect(tester.widget<TextField>(textField).focusNode?.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );
}

ProductData _product(int index) {
  return ProductData(
    id: 'product-$index',
    image: AppAssets.defaultProduct,
    title: 'Product $index',
    brand: 'Market',
    price: '${index + 1}.00',
    oldPrice: null,
    discount: '',
    tags: const [],
  );
}
