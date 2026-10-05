import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/domain/repositories/store_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/store_view.dart';
import 'package:yalla_market/features/store/presentation/views/latest_stores_view.dart';
import 'package:yalla_market/features/store/presentation/widgets/store_highlights_sections.dart';
import 'package:yalla_market/features/store/presentation/widgets/store_market_card.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  testWidgets('store page is dedicated to every category without view all', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _storeData();
    final storeCubit = StoreCubit(GetStoreUseCase(_StoreRepository(store)));
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

    expect(
      find.byKey(const ValueKey('all_store_categories_grid')),
      findsOneWidget,
    );
    for (var index = 0; index < store.classifications.length; index++) {
      expect(
        find.byKey(ValueKey('store_category_category-$index')),
        findsOneWidget,
      );
    }
    expect(find.text('View all'), findsNothing);
    expect(find.text('Popular Stores'), findsNothing);
    expect(find.text('Latest Stores'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home store highlights fit a compact iPhone-sized viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StoreHighlightsSections(store: _storeData()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Popular Stores'), findsOneWidget);
    expect(find.text('Latest Stores'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('popular_stores_horizontal_slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('latest_stores_horizontal_slider')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('popular stores share one row without category chips', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    BrandProductsRouteArgs? openedStore;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          expect(settings.name, AppRoutes.brandProducts);
          openedStore = settings.arguments! as BrandProductsRouteArgs;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Opened store')),
          );
        },
        home: Scaffold(body: StoreHighlightsSections(store: _storeData())),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('popular_store_category_selector')),
      findsNothing,
    );
    expect(find.text('Category 0'), findsNothing);
    final slider = find.byKey(
      const ValueKey('popular_stores_horizontal_slider'),
    );
    expect(tester.widget<ListView>(slider).semanticChildCount, 2);
    expect(
      find.byKey(const ValueKey('popular_store_market-category-0')),
      findsOneWidget,
    );
    await tester.drag(slider, const Offset(-400, 0));
    await tester.pumpAndSettle();
    final secondStore = find.byKey(
      const ValueKey('popular_store_market-category-2'),
    );
    expect(secondStore, findsOneWidget);
    await tester.tap(secondStore);
    await tester.pumpAndSettle();

    expect(openedStore?.marketId, 'market-category-2');
    expect(openedStore?.classificationId, 'category-2');
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'store sliders show compact cards with a preview at $width in $direction',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final store = _storeData();
          await tester.pumpWidget(
            MaterialApp(
              home: Directionality(
                textDirection: direction,
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: StoreHighlightsSections(
                      store: store.copyWith(
                        latestMarkets: store.popularMarkets,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          for (final prefix in ['popular', 'latest']) {
            final viewport = tester.getRect(
              find.byKey(ValueKey('${prefix}_stores_horizontal_slider')),
            );
            final first = tester.getRect(
              find.byKey(ValueKey('${prefix}_store_market-category-0')),
            );
            final second = tester.getRect(
              find.byKey(ValueKey('${prefix}_store_market-category-2')),
            );
            expect(first.height, StoreMarketCard.height);
            expect(viewport.intersect(first).width, closeTo(first.width, 0.1));
            expect(viewport.intersect(second).width, greaterThan(0));
            expect(first.width, lessThan(viewport.width));
            expect(first.width, greaterThan(viewport.width * 0.75));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final count in [0, 5, 6]) {
    testWidgets('popular preview handles $count stores and view all', (
      tester,
    ) async {
      final store = _storeData().copyWith(
        latestMarkets: [],
        popularMarkets: List.generate(
          count,
          (index) => StoreMarketData.fromJson({
            'id': 'popular-$index',
            'name': 'Popular $index',
            'is_popular': true,
          }),
        ),
      );
      String? openedRoute;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            openedRoute = settings.name;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('All popular stores')),
            );
          },
          home: Scaffold(body: StoreHighlightsSections(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('popular_store_category_selector')),
        findsNothing,
      );
      if (count == 0) {
        expect(find.text('Popular Stores'), findsNothing);
        return;
      }
      final slider = find.byKey(
        const ValueKey('popular_stores_horizontal_slider'),
      );
      expect(
        tester.widget<ListView>(slider).semanticChildCount,
        count > 5 ? 6 : count,
      );
      await tester.drag(slider, const Offset(-3000, 0));
      await tester.pumpAndSettle();
      final viewAll = find.byKey(const ValueKey('popular_stores_view_all'));
      expect(viewAll, count > 5 ? findsOneWidget : findsNothing);
      expect(
        find.byKey(const ValueKey('popular_store_popular-5')),
        findsNothing,
      );
      if (count > 5) {
        await tester.tap(viewAll);
        await tester.pumpAndSettle();
        expect(openedRoute, AppRoutes.popularStores);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'popular view all includes stores beyond fifteen and opens a store',
    (tester) async {
      final store = _storeData().copyWith(
        popularMarkets: List.generate(
          17,
          (index) => StoreMarketData.fromJson({
            'id': 'popular-$index',
            'name': 'Popular $index',
            'classification_id': 'category-${index % 3}',
            'is_popular': true,
          }),
        ),
      );
      final cubit = StoreCubit(GetStoreUseCase(_StoreRepository(store)));
      addTearDown(cubit.close);
      BrandProductsRouteArgs? openedStore;
      await tester.pumpWidget(
        BlocProvider<StoreCubit>.value(
          value: cubit,
          child: MaterialApp(
            onGenerateRoute: (settings) {
              expect(settings.name, AppRoutes.brandProducts);
              openedStore = settings.arguments! as BrandProductsRouteArgs;
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Opened store')),
              );
            },
            home: const LatestStoresView(showPopularStores: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Popular Stores'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('latest_stores_page_market-category-1')),
        findsNothing,
      );
      final last = find.byKey(const ValueKey('popular_stores_page_popular-16'));
      await tester.scrollUntilVisible(last, 500);
      await tester.pumpAndSettle();
      expect(last, findsOneWidget);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(openedStore?.marketId, 'popular-16');
      expect(openedStore?.classificationId, 'category-1');
      expect(tester.takeException(), isNull);
    },
  );
}

StoreData _storeData() {
  final classifications = List.generate(
    9,
    (index) => StoreClassificationData(
      id: 'category-$index',
      name: 'Category $index',
      marketCount: 1,
      products: const [],
      image: '',
      accentColorValue: 0xFF4F60F6,
      classificationType: switch (index % 3) {
        0 => 'featured',
        1 => 'popular',
        _ => 'normal',
      },
    ),
  );
  final markets = {
    for (final classification in classifications)
      classification.id: [
        StoreMarketData(
          id: 'market-${classification.id}',
          name: 'Market ${classification.id}',
          branch: '',
          status: 'active',
          classificationId: classification.id,
          products: const [],
          image: '',
          accentColorValue: 0xFF4F60F6,
          isPopular: ['category-0', 'category-2'].contains(classification.id),
        ),
      ],
  };

  return StoreData(
    commonClassifications: classifications,
    classifications: classifications,
    marketsByClassificationId: markets,
    latestMarkets: markets['category-1']!,
  );
}

class _StoreRepository implements StoreRepository {
  const _StoreRepository(this.store);

  final StoreData store;

  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async {
    return ApiResult.success(store);
  }

  @override
  Future<ApiResult<StoreMarketData>> getMarket(String marketId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<List<StoreMarketData>>> getClassificationMarkets(
    String classificationId,
  ) async {
    return ApiResult.success(store.marketsFor(classificationId));
  }
}
