import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/domain/computation_executor.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_results_view.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ComputationExecutor>(
      const InlineComputationExecutor(),
    );
  });

  tearDown(() => sl.reset());

  testWidgets(
    'sliver results build only nearby cards and retain page controls',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final cartCubit = makeCartCubit();
      final wishlistCubit = makeWishlistCubit();
      addTearDown(cartCubit.close);
      addTearDown(wishlistCubit.close);
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cartCubit),
            BlocProvider<WishlistCubit>.value(value: wishlistCubit),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                controller: controller,
                slivers: [
                  ProductResultsView(
                    sliver: true,
                    products: List.generate(250, _product),
                    pageSize: 100,
                    initialSortOption: 'Newest',
                    useHomeSearchStyle: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('store_product_search_field')),
        findsOneWidget,
      );
      expect(find.byType(ProductCardVertical).evaluate().length, lessThan(20));

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('2/3'), findsOneWidget);
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ProductCardVertical &&
              widget.productId == 'product-100',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sliver results preserve search and refresh state without rebuilding every card',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final cartCubit = makeCartCubit();
      final wishlistCubit = makeWishlistCubit();
      addTearDown(cartCubit.close);
      addTearDown(wishlistCubit.close);
      final status = ValueNotifier(ProductResultsStatus.ready);
      addTearDown(status.dispose);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cartCubit),
            BlocProvider<WishlistCubit>.value(value: wishlistCubit),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<ProductResultsStatus>(
                valueListenable: status,
                builder: (_, value, _) => CustomScrollView(
                  slivers: [
                    ProductResultsView(
                      sliver: true,
                      status: value,
                      products: List.generate(1000, _product),
                      pageSize: 100,
                      useHomeSearchStyle: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = find.descendant(
        of: find.byKey(const ValueKey('store_product_search_field')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'Product 12');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('product_add_to_cart_product-12')),
        findsOneWidget,
      );

      status.value = ProductResultsStatus.loading;
      await tester.pump();
      status.value = ProductResultsStatus.ready;
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(field).controller!.text, 'Product 12');
      expect(
        find.byKey(const ValueKey('product_add_to_cart_product-12')),
        findsOneWidget,
      );
      expect(find.byType(ProductCardVertical).evaluate().length, lessThan(20));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('whitespace search keeps the clear suffix and can be cleared', (
    tester,
  ) async {
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
        child: const MaterialApp(
          home: Scaffold(
            body: ProductResultsView(products: [_whitespaceProduct]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.enterText(field, '   ');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(find.byTooltip('Clear'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

const _whitespaceProduct = ProductData(
  id: 'whitespace',
  image: AppAssets.defaultProduct,
  title: 'Product whitespace',
  brand: 'Market',
  price: '1.00',
  oldPrice: null,
  discount: '',
  tags: [],
);

ProductData _product(int index) => ProductData(
  id: 'product-$index',
  image: AppAssets.defaultProduct,
  title: 'Product $index',
  brand: 'Market',
  price: '${index + 1}.00',
  oldPrice: null,
  discount: '',
  tags: const [],
);
