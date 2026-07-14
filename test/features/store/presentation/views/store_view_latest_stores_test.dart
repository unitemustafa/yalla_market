import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
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

    await tester.drag(slider, const Offset(-2200, 0));
    await tester.pumpAndSettle();
    final viewAll = find.byKey(const ValueKey('latest_stores_view_all'));
    expect(viewAll, findsOneWidget);

    await tester.tap(viewAll);
    await tester.pumpAndSettle();
    expect(find.text('Latest stores'), findsOneWidget);
  });

  testWidgets(
    'popular store tabs stay scrollable and exclude empty categories',
    (tester) async {
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

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.isScrollable, isTrue);
      expect(find.text('No popular stores here'), findsNothing);
      expect(tester.takeException(), isNull);

      final callsBeforeRefresh = repository.calls;
      final popularStoresList = find.descendant(
        of: find.byType(TabBarView),
        matching: find.byType(ListView),
      );
      expect(popularStoresList, findsOneWidget);

      await tester.fling(popularStoresList, const Offset(0, 500), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(repository.calls, callsBeforeRefresh + 1);
      expect(find.text('Content updated'), findsOneWidget);
    },
  );
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
      products: const [],
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

StoreData _storeWithPopularMarkets() {
  final classifications = List.generate(
    4,
    (index) => StoreClassificationData(
      id: 'popular-$index',
      name: index == 3
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
    for (var index = 0; index < 3; index++)
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
    'popular-3': [
      const StoreMarketData(
        id: 'regular-market',
        name: 'Regular Market',
        branch: '',
        status: 'active',
        classificationId: 'popular-3',
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
  );
}

class _StoreRepository implements StoreRepository {
  _StoreRepository(this.store);

  final StoreData store;
  int calls = 0;

  @override
  Future<ApiResult<StoreData>> getStore() async {
    calls++;
    return ApiResult.success(store);
  }
}
