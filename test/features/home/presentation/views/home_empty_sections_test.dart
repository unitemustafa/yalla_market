import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/routing/app_route_arguments.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
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
    expect(find.text('View all'), findsNothing);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Popular Products'), findsNothing);
    expect(find.text('Latest Products'), findsNothing);
    expect(find.byKey(const ValueKey('home_empty_products')), findsNothing);
  });

  testWidgets('shows View all when popular categories exceed four', (
    tester,
  ) async {
    RouteSettings? capturedSettings;
    await _pumpSections(
      tester,
      home: HomeData(
        location: null,
        offers: const [],
        categories: List.generate(5, _categoryFor),
        products: const [],
      ),
      catalogState: const ProductCatalogReady([], city: _city),
      onGenerateRoute: (settings) {
        capturedSettings = settings;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('All categories route')),
        );
      },
    );

    expect(find.text('Popular Categories'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('popular_categories_list')),
        matching: find.byType(GestureDetector),
      ),
      findsNWidgets(4),
    );

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    expect(capturedSettings?.name, AppRoutes.categories);
    final args = capturedSettings?.arguments as CategoriesRouteArgs;
    expect(args.categories.map((category) => category.id), [
      'category-0',
      'category-1',
      'category-2',
      'category-3',
      'category-4',
    ]);
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

  testWidgets('caps both product sections at five then adds view all', (
    tester,
  ) async {
    final popularProducts = List.generate(
      6,
      (index) => _product(id: 'popular-$index', isPopular: true),
    );
    final latestProducts = List.generate(
      6,
      (index) => _product(id: 'latest-$index', isPopular: false),
    );

    await _pumpSections(
      tester,
      home: HomeData(
        location: null,
        offers: const [],
        categories: const [],
        products: popularProducts,
      ),
      catalogState: ProductCatalogReady(latestProducts, city: _city),
    );

    final popularSlider = tester.widget<ListView>(
      find.byKey(const ValueKey('popular_products_horizontal_slider')),
    );
    final latestSlider = tester.widget<ListView>(
      find.byKey(const ValueKey('latest_products_horizontal_slider')),
    );
    expect(popularSlider.semanticChildCount, 6);
    expect(latestSlider.semanticChildCount, 6);
    expect(
      find.byKey(const ValueKey('popular_product_popular-5')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('latest_product_latest-5')), findsNothing);
  });
}

Future<void> _pumpSections(
  WidgetTester tester, {
  required HomeData home,
  required ProductCatalogState catalogState,
  RouteFactory? onGenerateRoute,
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
        onGenerateRoute: onGenerateRoute,
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

CategoryData _categoryFor(int index) => CategoryData(
  id: 'category-$index',
  name: 'Category $index',
  slug: 'category-$index',
  productCount: index + 1,
  image: AppAssets.defaultCategory,
  galleryImages: const [],
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
