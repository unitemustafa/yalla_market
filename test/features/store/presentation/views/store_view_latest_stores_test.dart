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

class _StoreRepository implements StoreRepository {
  const _StoreRepository(this.store);

  final StoreData store;

  @override
  Future<ApiResult<StoreData>> getStore() async => ApiResult.success(store);
}
