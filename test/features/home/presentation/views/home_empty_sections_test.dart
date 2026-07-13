import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/home/domain/entities/home_data.dart';
import 'package:yalla_market/features/home/presentation/views/home_view.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/store/domain/entities/category_data.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/presentation/cubit/product_catalog_state.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  testWidgets('shows one empty state and hides every empty home section', (
    tester,
  ) async {
    await _pumpSections(
      tester,
      home: HomeData(
        location: null,
        offers: const [],
        categories: const [],
        products: const [],
      ),
      catalogState: const ProductCatalogReady([], city: _city),
    );

    expect(find.byKey(const ValueKey('home_empty_products')), findsOneWidget);
    expect(find.text('No products available'), findsOneWidget);
    expect(find.text('Popular Categories'), findsNothing);
    expect(find.text('Popular Products'), findsNothing);
    expect(find.text('Latest Products'), findsNothing);
  });

  testWidgets('shows a popular category that contains an available shop', (
    tester,
  ) async {
    await _pumpSections(
      tester,
      home: HomeData(
        location: null,
        offers: const [],
        categories: const [_category],
        products: const [],
      ),
      catalogState: const ProductCatalogReady([], city: _city),
    );

    expect(find.text('Popular Categories'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Popular Products'), findsNothing);
    expect(find.text('Latest Products'), findsNothing);
    expect(find.byKey(const ValueKey('home_empty_products')), findsNothing);
  });

  testWidgets('shows latest products only when popular products are empty', (
    tester,
  ) async {
    await _pumpSections(
      tester,
      home: const HomeData(
        location: null,
        offers: [],
        categories: [],
        products: [],
      ),
      catalogState: ProductCatalogReady([
        _product(id: 'latest', isPopular: false),
      ], city: _city),
    );

    expect(find.text('Latest Products'), findsOneWidget);
    expect(find.text('Popular Categories'), findsNothing);
    expect(find.text('Popular Products'), findsNothing);
    expect(find.byKey(const ValueKey('home_empty_products')), findsNothing);
  });

  testWidgets(
    'hides latest products when only popular products are available',
    (tester) async {
      await _pumpSections(
        tester,
        home: HomeData(
          location: null,
          offers: const [],
          categories: const [_category],
          products: [_product(id: 'popular', isPopular: true)],
        ),
        catalogState: const ProductCatalogReady([], city: _city),
      );

      expect(find.text('Popular Categories'), findsOneWidget);
      expect(find.text('Popular Products'), findsOneWidget);
      expect(find.text('Latest Products'), findsNothing);
      expect(find.byKey(const ValueKey('home_empty_products')), findsNothing);
    },
  );
}

Future<void> _pumpSections(
  WidgetTester tester, {
  required HomeData home,
  required ProductCatalogState catalogState,
}) async {
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
          body: SingleChildScrollView(
            child: HomeCatalogSections(home: home, catalogState: catalogState),
          ),
        ),
      ),
    ),
  );
}

const _city = CityData(name: 'Cairo', slug: 'cairo');

const _category = CategoryData(
  id: 'category',
  name: 'Category',
  slug: 'category',
  productCount: 1,
  image: AppAssets.defaultCategory,
  galleryImages: [],
  accentColorValue: 0xFF5568FE,
);

ProductData _product({required String id, required bool isPopular}) {
  return ProductData(
    id: id,
    image: AppAssets.defaultProduct,
    title: id,
    brand: 'Market',
    price: '120.00',
    oldPrice: null,
    discount: '',
    tags: const [],
    isPopular: isPopular,
  );
}
