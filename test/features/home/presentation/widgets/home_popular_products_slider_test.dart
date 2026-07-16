import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/home/presentation/widgets/home_popular_products_slider.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  testWidgets('uses five scrollable vertical cards then view all', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cartCubit = makeCartCubit();
    final wishlistCubit = makeWishlistCubit();
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);
    var openedAllProducts = false;
    final products = [
      _product(90, title: 'Shoe', isPopular: false),
      ...List.generate(7, _product),
      _product(91, title: 'Cucumber', isPopular: false),
    ];

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: HomeProductsSlider(
                products: products,
                onViewAll: () => openedAllProducts = true,
              ),
            ),
          ),
        ),
      ),
    );

    final sliderFinder = find.byKey(
      const ValueKey('popular_products_horizontal_slider'),
    );
    final listView = tester.widget<ListView>(sliderFinder);
    expect(listView.scrollDirection, Axis.horizontal);
    expect(listView.semanticChildCount, 6);
    expect(find.text('Shoe'), findsNothing);
    expect(find.text('Cucumber'), findsNothing);
    expect(
      find.byKey(const ValueKey('popular_product_product-6')),
      findsNothing,
    );

    final firstCard = find.byKey(const ValueKey('popular_product_product-1'));
    final imageCenter = tester.getCenter(
      find.descendant(of: firstCard, matching: find.byType(AppImage)),
    );
    final titleCenter = tester.getCenter(
      find.descendant(of: firstCard, matching: find.text('Product 1')),
    );
    expect(imageCenter.dy, lessThan(titleCenter.dy));
    final imageRect = tester.getRect(
      find.descendant(of: firstCard, matching: find.byType(AppImage)),
    );
    final wishlistCenter = tester.getCenter(
      find.byKey(const ValueKey('product_wishlist_product-1')),
    );
    final addCenter = tester.getCenter(
      find.byKey(const ValueKey('product_add_to_cart_product-1')),
    );
    expect(imageRect.contains(wishlistCenter), isTrue);
    expect(wishlistCenter.dy, lessThan(addCenter.dy));
    expect(find.text('Add to cart'), findsWidgets);

    await tester.drag(sliderFinder, const Offset(-1800, 0));
    await tester.pumpAndSettle();
    final viewAll = find.byKey(const ValueKey('popular_products_view_all'));
    expect(viewAll, findsOneWidget);
    await tester.tap(viewAll);
    expect(openedAllProducts, isTrue);
  });

  testWidgets('hides view all when there are exactly five products', (
    tester,
  ) async {
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
          home: Scaffold(
            body: HomeProductsSlider(
              products: List.generate(5, _product),
              onViewAll: () {},
            ),
          ),
        ),
      ),
    );

    final listView = tester.widget<ListView>(
      find.byKey(const ValueKey('popular_products_horizontal_slider')),
    );
    expect(listView.semanticChildCount, 5);
    expect(
      find.byKey(const ValueKey('popular_products_view_all')),
      findsNothing,
    );
  });

  testWidgets('latest slider keeps API order and shows view all after five', (
    tester,
  ) async {
    final cartCubit = makeCartCubit();
    final wishlistCubit = makeWishlistCubit();
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);
    final products = List.generate(
      8,
      (index) => _product(
        index,
        title: index == 0 ? 'Newest product' : 'Older product $index',
        isPopular: false,
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HomeProductsSlider(
              products: products,
              mode: HomeProductsSliderMode.latest,
              onViewAll: () {},
            ),
          ),
        ),
      ),
    );

    final slider = find.byKey(
      const ValueKey('latest_products_horizontal_slider'),
    );
    final listView = tester.widget<ListView>(slider);
    expect(listView.semanticChildCount, 6);
    expect(
      find.byKey(const ValueKey('latest_product_product-1')),
      findsOneWidget,
    );
    expect(find.text('Newest product'), findsOneWidget);

    await tester.drag(slider, const Offset(-1800, 0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('latest_products_view_all')),
      findsOneWidget,
    );
  });
}

ProductData _product(int index, {String? title, bool isPopular = true}) {
  final number = index + 1;
  return ProductData(
    id: 'product-$number',
    image: AppAssets.defaultProduct,
    title: title ?? 'Product $number',
    brand: 'Market',
    price: '120.00',
    oldPrice: null,
    discount: '',
    tags: const [],
    isPopular: isPopular,
  );
}
