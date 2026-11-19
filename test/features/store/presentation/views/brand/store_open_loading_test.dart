import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/offers/domain/entities/offer_data.dart';
import 'package:yalla_market/features/offers/domain/repositories/offer_repository.dart';
import 'package:yalla_market/features/offers/domain/usecases/get_offers_usecase.dart';
import 'package:yalla_market/features/offers/presentation/cubit/offer_catalog_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_product_page.dart';
import 'package:yalla_market/features/store/domain/repositories/store_products_repository.dart';
import 'package:yalla_market/features/store/domain/repositories/store_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_market_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_products_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_products_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';

void main() {
  for (final hasSummary in [true, false]) {
    testWidgets(
      hasSummary
          ? 'opens market without waiting for a stale summary refresh'
          : 'waits for the initial summary before merging market details',
      (tester) async {
        final repository = _StoreRepository();
        final offersRepository = _OffersRepository();
        final store = StoreCubit(
          GetStoreUseCase(repository),
          getMarket: GetMarketUseCase(repository),
        );
        final offers = OfferCatalogCubit(GetOffersUseCase(offersRepository));
        sl.registerFactory<StoreProductsCubit>(
          () => StoreProductsCubit(
            const GetStoreProductsUseCase(_EmptyProducts()),
          ),
        );
        addTearDown(() async {
          await store.close();
          await offers.close();
          await sl.unregister<StoreProductsCubit>();
        });
        if (hasSummary) {
          await store.loadStore();
          store.invalidate();
        }
        repository.pendingSummary = Completer<ApiResult<StoreData>>();

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: store),
              BlocProvider.value(value: offers),
            ],
            child: const MaterialApp(
              home: BrandProductsView(
                brand: 'Store',
                logo: '',
                productCount: '',
                marketId: 'market',
              ),
            ),
          ),
        );
        await tester.pump();
        expect(offersRepository.calls, 1);
        expect(repository.marketCalls, hasSummary ? 1 : 0);
        expect(repository.pendingSummary!.isCompleted, isFalse);

        repository.pendingSummary!.complete(const ApiResult.success(_summary));
        await tester.pump();
        await tester.pump();
        expect(repository.marketCalls, 1);
        expect(store.state.data!.marketsFor('test').single.id, 'market');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}

const _market = StoreMarketData(
  id: 'market',
  name: 'Store',
  branch: '',
  status: 'active',
  classificationId: 'test',
  products: [],
  image: '',
  accentColorValue: 0xFF013C7E,
);
const _summary = StoreData(
  commonClassifications: [],
  classifications: [],
  marketsByClassificationId: {
    'test': [_market],
  },
);

class _StoreRepository implements StoreRepository {
  Completer<ApiResult<StoreData>>? pendingSummary;
  var marketCalls = 0;

  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async =>
      pendingSummary?.future ?? const ApiResult.success(_summary);

  @override
  Future<ApiResult<StoreMarketData>> getMarket(String marketId) async {
    marketCalls++;
    return const ApiResult.success(_market);
  }

  @override
  Future<ApiResult<List<StoreMarketData>>> getClassificationMarkets(
    String classificationId,
  ) async => const ApiResult.success([_market]);
}

class _OffersRepository implements OfferRepository {
  var calls = 0;
  @override
  Future<ApiResult<List<OfferData>>> getOffers() async {
    calls++;
    return const ApiResult.success([]);
  }
}

class _EmptyProducts implements StoreProductsRepository {
  const _EmptyProducts();
  @override
  Future<ApiResult<StoreProductPage>> getProducts(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  }) async => const ApiResult.success(
    StoreProductPage(products: [], count: 0, hasMore: false),
  );
}
