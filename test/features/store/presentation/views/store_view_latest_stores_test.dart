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
import 'package:yalla_market/features/store/presentation/widgets/store_highlights_sections.dart';

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

  testWidgets('popular category chips can be enabled again', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StoreHighlightsSections(
              store: _storeData(),
              showPopularStoreCategories: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('popular_store_category_selector')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('popular_store_category_category-2')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('popular_store_market-category-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('popular_store_market-category-0')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
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
