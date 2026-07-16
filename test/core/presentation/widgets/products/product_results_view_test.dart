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
