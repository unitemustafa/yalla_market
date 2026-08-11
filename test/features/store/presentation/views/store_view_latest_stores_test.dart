import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
          isPopular: classification.id == 'category-0',
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
