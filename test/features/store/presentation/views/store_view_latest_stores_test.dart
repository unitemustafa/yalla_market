import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/core/routing/app_route_arguments.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/domain/repositories/store_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/store_view.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  testWidgets('shows six latest stores then opens view all', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storeCubit = StoreCubit(GetStoreUseCase(_StoreRepository(_store())));
    final cartCubit = makeCartCubit();
    addTearDown(storeCubit.close);
    addTearDown(cartCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<StoreCubit>.value(value: storeCubit),
          BlocProvider<CartCubit>.value(value: cartCubit),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.latestStores) {
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Latest stores')),
              );
            }
            return null;
          },
          home: const StoreView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latest Stores'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(NestedScrollView), findsNothing);
    final storeScroll = find.byKey(
      const ValueKey('store_without_popular_scroll'),
    );
    expect(storeScroll, findsOneWidget);
    final initialStoreTop = tester.getTopLeft(find.text('Store')).dy;
    await tester.drag(storeScroll, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Store')).dy,
      closeTo(initialStoreTop, 1),
    );
    final slider = find.byKey(
      const ValueKey('latest_stores_horizontal_slider'),
    );
    expect(tester.widget<ListView>(slider).semanticChildCount, 7);
    expect(find.byKey(const ValueKey('latest_store_market-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('latest_store_market-7')), findsNothing);
    expect(
      find.byKey(const ValueKey('latest_store_market-1_product_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('latest_store_market-1_product_2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('latest_store_market-1_product_3')),
      findsNothing,
    );
    final emptyStoreImage = tester.widget<AppImage>(
      find.byKey(const ValueKey('latest_store_market-2_default_0')),
    );
    expect(emptyStoreImage.source, AppAssets.emptyStoreLight);
    expect(
      find.byKey(const ValueKey('latest_store_market-2_default_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('latest_store_market-2_default_2')),
      findsOneWidget,
    );

    await tester.drag(slider, const Offset(-2200, 0));
    await tester.pumpAndSettle();
    final viewAll = find.byKey(const ValueKey('latest_stores_view_all'));
    expect(viewAll, findsOneWidget);

    await tester.tap(viewAll);
    await tester.pumpAndSettle();
    expect(find.text('Latest stores'), findsOneWidget);
  });

  testWidgets('popular stores use filters and one stable page scroll', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _StoreRepository(_storeWithPopularMarkets());
    final storeCubit = StoreCubit(GetStoreUseCase(repository));
    final cartCubit = makeCartCubit();
    addTearDown(storeCubit.close);
    addTearDown(cartCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<StoreCubit>.value(value: storeCubit),
          BlocProvider<CartCubit>.value(value: cartCubit),
        ],
        child: const MaterialApp(home: StoreView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);
    expect(find.byType(NestedScrollView), findsNothing);
    expect(find.text('No popular stores here'), findsNothing);
    final categorySelector = find.byKey(
      const ValueKey('popular_store_category_selector'),
    );
    expect(categorySelector, findsOneWidget);
    expect(tester.widget<ListView>(categorySelector).semanticChildCount, 5);
    final firstCategorySize = tester.getSize(
      find.byKey(const ValueKey('popular_store_category_popular-0')),
    );
    final secondCategorySize = tester.getSize(
      find.byKey(const ValueKey('popular_store_category_popular-1')),
    );
    expect(firstCategorySize, const Size(128, 40));
    expect(secondCategorySize, firstCategorySize);
    final firstChip = find.byKey(
      const ValueKey('popular_store_category_popular-0'),
    );
    final firstLabel = find.descendant(
      of: firstChip,
      matching: find.text('A very long popular category name number 0'),
    );
    final firstCount = find.descendant(of: firstChip, matching: find.text('1'));
    expect(
      tester.getCenter(firstLabel).dx,
      lessThan(tester.getCenter(firstCount).dx),
    );
    expect(find.text('Popular picks for you'), findsNothing);
    expect(
      tester.widget<ListView>(categorySelector).scrollDirection,
      Axis.horizontal,
    );
    final popularSlider = find.byKey(
      const ValueKey('popular_stores_horizontal_slider'),
    );
    expect(popularSlider, findsOneWidget);
    expect(
      tester.widget<ListView>(popularSlider).scrollDirection,
      Axis.horizontal,
    );
    expect(
      find.byKey(const ValueKey('popular_store_popular-market-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('popular_store_popular-market-0_default_0')),
      findsOneWidget,
    );

    await tester.drag(categorySelector, const Offset(-140, 0));
    await tester.pumpAndSettle();
    final secondCategory = find.byKey(
      const ValueKey('popular_store_category_popular-1'),
    );
    await tester.tap(secondCategory);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('popular_store_popular-market-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('popular_store_popular-market-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('store_refresh_button')), findsNothing);
    final popularHeading = tester.widget<Text>(find.text('Popular Stores'));
    final latestHeading = tester.widget<Text>(find.text('Latest Stores'));
    expect(popularHeading.style?.fontSize, latestHeading.style?.fontSize);
    expect(
      tester.getTopLeft(find.text('Popular Stores')).dy,
      lessThan(tester.getTopLeft(find.text('Latest Stores')).dy),
    );

    await tester.drag(categorySelector, const Offset(-500, 0));
    await tester.pumpAndSettle();
    final fifthCategory = find.byKey(
      const ValueKey('popular_store_category_popular-4'),
    );
    expect(fifthCategory, findsOneWidget);
    await tester.tap(fifthCategory);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('popular_store_popular-market-4')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final pageScroll = find.byKey(const ValueKey('store_scroll'));
    expect(pageScroll, findsOneWidget);
    await tester.fling(pageScroll, const Offset(0, 2000), 2000);
    await tester.pumpAndSettle();
    final callsBeforeRefresh = repository.calls;
    await tester.drag(pageScroll, const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.calls, callsBeforeRefresh + 1);
  });

  testWidgets('empty latest store uses the compact dark placeholder', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storeCubit = StoreCubit(GetStoreUseCase(_StoreRepository(_store())));
    final cartCubit = makeCartCubit();
    addTearDown(storeCubit.close);
    addTearDown(cartCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<StoreCubit>.value(value: storeCubit),
          BlocProvider<CartCubit>.value(value: cartCubit),
        ],
        child: MaterialApp(theme: ThemeData.dark(), home: const StoreView()),
      ),
    );
    await tester.pumpAndSettle();

    final emptyStoreImage = tester.widget<AppImage>(
      find.byKey(const ValueKey('latest_store_market-2_default_0')),
    );
    expect(emptyStoreImage.source, AppAssets.emptyStoreDark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('odd featured category fills the final row deliberately', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storeCubit = StoreCubit(
      GetStoreUseCase(_StoreRepository(_storeWithThreeFeaturedCategories())),
    );
    final cartCubit = makeCartCubit();
    addTearDown(storeCubit.close);
    addTearDown(cartCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<StoreCubit>.value(value: storeCubit),
          BlocProvider<CartCubit>.value(value: cartCubit),
        ],
        child: const MaterialApp(home: StoreView()),
      ),
    );
    await tester.pumpAndSettle();

    final first = tester.getSize(
      find.byKey(const ValueKey('featured_category_featured-0')),
    );
    final last = tester.getSize(
      find.byKey(const ValueKey('featured_category_featured-2')),
    );
    expect(last.width, greaterThan(first.width * 1.9));
    expect(first.height, 92);
    expect(last.height, 92);
    expect(tester.takeException(), isNull);
  });

  testWidgets('featured View all passes every displayed category', (
    tester,
  ) async {
    final store = _storeWithFeaturedOverflow();
    final storeCubit = StoreCubit(GetStoreUseCase(_StoreRepository(store)));
    final cartCubit = makeCartCubit();
    RouteSettings? capturedSettings;
    addTearDown(storeCubit.close);
    addTearDown(cartCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<StoreCubit>.value(value: storeCubit),
          BlocProvider<CartCubit>.value(value: cartCubit),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            capturedSettings = settings;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Categories route')),
            );
          },
          home: const StoreView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    expect(capturedSettings?.name, AppRoutes.categories);
    final args = capturedSettings?.arguments as CategoriesRouteArgs;
    expect(args.categories.map((category) => category.id), [
      'featured-0',
      'featured-1',
      'featured-2',
      'featured-3',
      'normal-4',
    ]);
  });
}

StoreData _store() {
  final markets = List.generate(
    7,
    (index) => StoreMarketData(
      id: 'market-${index + 1}',
      name: 'Market ${index + 1}',
      branch: '',
      status: 'active',
      classificationId: 'featured',
      products: index == 0
          ? List.generate(4, (productIndex) => _product(productIndex))
          : const [],
      image: '',
      accentColorValue: 0xFF4F60F6,
      createdAt: DateTime.utc(2026, 7, 13).subtract(Duration(days: index)),
    ),
  );
  const classification = StoreClassificationData(
    id: 'featured',
    name: 'Shoes and clothes',
    marketCount: 7,
    products: [],
    image: '',
    accentColorValue: 0xFF4F60F6,
    classificationType: 'featured',
  );

  return StoreData(
    commonClassifications: const [classification],
    classifications: const [classification],
    marketsByClassificationId: {'featured': markets},
    latestMarkets: markets,
  );
}

ProductData _product(int index) {
  return ProductData(
    id: 'product-$index',
    image: AppAssets.defaultProduct,
    title: 'Product $index',
    brand: 'Market 1',
    price: '100',
    oldPrice: null,
    discount: '',
    tags: const [],
  );
}

StoreData _storeWithPopularMarkets() {
  final classifications = List.generate(
    6,
    (index) => StoreClassificationData(
      id: 'popular-$index',
      name: index == 5
          ? 'No popular stores here'
          : 'A very long popular category name number $index',
      marketCount: 1,
      products: const [],
      image: '',
      accentColorValue: 0xFF4F60F6,
      classificationType: 'popular',
    ),
  );
  final markets = <String, List<StoreMarketData>>{
    for (var index = 0; index < 5; index++)
      'popular-$index': [
        StoreMarketData(
          id: 'popular-market-$index',
          name: 'Popular Market $index',
          branch: '',
          status: 'active',
          classificationId: 'popular-$index',
          products: const [],
          image: '',
          accentColorValue: 0xFF4F60F6,
          isPopular: true,
        ),
      ],
    'popular-5': [
      const StoreMarketData(
        id: 'regular-market',
        name: 'Regular Market',
        branch: '',
        status: 'active',
        classificationId: 'popular-5',
        products: [],
        image: '',
        accentColorValue: 0xFF4F60F6,
      ),
    ],
  };

  return StoreData(
    commonClassifications: const [],
    classifications: classifications,
    marketsByClassificationId: markets,
    latestMarkets: markets['popular-0']!,
  );
}

StoreData _storeWithThreeFeaturedCategories() {
  final classifications = List.generate(
    3,
    (index) => StoreClassificationData(
      id: 'featured-$index',
      name: 'Featured category number $index with a long name',
      marketCount: index + 1,
      products: const [],
      image: '',
      accentColorValue: 0xFF4F60F6,
      classificationType: 'featured',
    ),
  );
  return StoreData(
    commonClassifications: classifications,
    classifications: classifications,
    marketsByClassificationId: const {},
  );
}

StoreData _storeWithFeaturedOverflow() {
  final classifications = List.generate(
    5,
    (index) => StoreClassificationData(
      id: index == 4 ? 'normal-4' : 'featured-$index',
      name: 'Category $index',
      marketCount: index + 1,
      products: const [],
      image: '',
      accentColorValue: 0xFF4F60F6,
      classificationType: index == 4 ? 'normal' : 'featured',
    ),
  );
  return StoreData(
    commonClassifications: classifications,
    classifications: classifications,
    marketsByClassificationId: const {},
  );
}

class _StoreRepository implements StoreRepository {
  _StoreRepository(this.store);

  final StoreData store;
  int calls = 0;

  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async {
    calls++;
    return ApiResult.success(store);
  }
}
