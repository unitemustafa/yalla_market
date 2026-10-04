import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/domain/repositories/store_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_classification_markets_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/get_market_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_cubit.dart';

void main() {
  test(
    'classification load replaces the limited summary exactly once',
    () async {
      final repository = _Repository();
      final cubit = StoreCubit(
        GetStoreUseCase(repository),
        getMarket: GetMarketUseCase(repository),
        getClassificationMarkets: GetClassificationMarketsUseCase(repository),
      );
      addTearDown(cubit.close);

      await cubit.loadStore();
      expect(cubit.state.data!.marketsFor('7').map((market) => market.id), [
        '1',
      ]);

      await cubit.ensureClassification('7');
      expect(cubit.state.data!.marketsFor('7').map((market) => market.id), [
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
      ]);
      expect(repository.classificationCalls, 1);

      await cubit.ensureClassification('7');
      expect(repository.classificationCalls, 1);
    },
  );

  test(
    'joins simultaneous requests for the same market and classification',
    () async {
      final repository = _Repository();
      final cubit = StoreCubit(
        GetStoreUseCase(repository),
        getMarket: GetMarketUseCase(repository),
        getClassificationMarkets: GetClassificationMarketsUseCase(repository),
      );
      addTearDown(cubit.close);
      await cubit.loadStore();

      repository.pendingMarket = Completer<ApiResult<StoreMarketData>>();
      final firstMarket = cubit.ensureMarket('1');
      final secondMarket = cubit.ensureMarket('1', force: true);
      await Future<void>.delayed(Duration.zero);
      expect(repository.marketCalls, 1);
      repository.pendingMarket!.complete(
        ApiResult.success(_market('1', productCount: 4)),
      );
      await Future.wait([firstMarket, secondMarket]);

      repository.pendingClassification =
          Completer<ApiResult<List<StoreMarketData>>>();
      final firstClassification = cubit.ensureClassification('7');
      final secondClassification = cubit.ensureClassification('7', force: true);
      await Future<void>.delayed(Duration.zero);
      expect(repository.classificationCalls, 1);
      repository.pendingClassification!.complete(
        ApiResult.success(
          List.generate(6, (index) => _market('${index + 1}', productCount: 1)),
        ),
      );
      await Future.wait([firstClassification, secondClassification]);
    },
  );

  test('an invalidated in-flight market response is fetched again', () async {
    final repository = _Repository();
    final cubit = StoreCubit(
      GetStoreUseCase(repository),
      getMarket: GetMarketUseCase(repository),
      getClassificationMarkets: GetClassificationMarketsUseCase(repository),
    );
    addTearDown(cubit.close);
    await cubit.loadStore();

    repository.pendingMarket = Completer<ApiResult<StoreMarketData>>();
    final request = cubit.ensureMarket('1');
    await Future<void>.delayed(Duration.zero);
    cubit.invalidate();
    repository.pendingMarket!.complete(
      ApiResult.success(_market('1', productCount: 4)),
    );
    await request;
    repository.pendingMarket = null;

    await cubit.ensureMarket('1');
    expect(repository.marketCalls, 2);
  });

  test(
    'refresh retries an in-flight market invalidated before its response',
    () async {
      final repository = _Repository();
      final cubit = StoreCubit(
        GetStoreUseCase(repository),
        getMarket: GetMarketUseCase(repository),
        getClassificationMarkets: GetClassificationMarketsUseCase(repository),
      );
      addTearDown(cubit.close);
      await cubit.loadStore();
      repository.pendingMarket = Completer<ApiResult<StoreMarketData>>();
      final oldRequest = cubit.ensureMarket('1');
      await Future<void>.delayed(Duration.zero);
      cubit.invalidate();
      final refresh = cubit.refreshIfStale();
      repository.pendingMarket!.complete(
        ApiResult.success(_market('1', productCount: 4)),
      );
      await Future.wait([oldRequest, refresh]);

      expect(repository.marketCalls, 2);
    },
  );

  test(
    'storefront load replaces a preview market even when it has products',
    () async {
      final repository = _Repository();
      final cubit = StoreCubit(
        GetStoreUseCase(repository),
        getMarket: GetMarketUseCase(repository),
        getClassificationMarkets: GetClassificationMarketsUseCase(repository),
      );
      addTearDown(cubit.close);

      await cubit.loadStore();
      expect(cubit.state.data!.marketsFor('7').single.products, hasLength(1));

      await cubit.ensureMarket('1');
      expect(cubit.state.data!.marketsFor('7').single.products, hasLength(4));
      expect(repository.marketCalls, 1);

      await cubit.ensureMarket('1');
      expect(repository.marketCalls, 1);
    },
  );

  test(
    'summary waits 60 seconds before revalidating a ready storefront',
    () async {
      var now = DateTime.utc(2030, 1, 1, 12);
      final repository = _Repository();
      final cubit = StoreCubit(
        GetStoreUseCase(repository),
        getMarket: GetMarketUseCase(repository),
        getClassificationMarkets: GetClassificationMarketsUseCase(repository),
        now: () => now,
      );
      addTearDown(cubit.close);

      await cubit.loadStore();
      now = now.add(const Duration(seconds: 59));
      await cubit.loadStore();
      expect(repository.storeCalls, 1);

      now = now.add(const Duration(seconds: 1));
      await cubit.loadStore();
      expect(repository.storeCalls, 2);
    },
  );

  test('market and classification detail freshness are independent', () async {
    var now = DateTime.utc(2030, 1, 1, 12);
    final repository = _Repository();
    final cubit = StoreCubit(
      GetStoreUseCase(repository),
      getMarket: GetMarketUseCase(repository),
      getClassificationMarkets: GetClassificationMarketsUseCase(repository),
      now: () => now,
    );
    addTearDown(cubit.close);

    await cubit.loadStore();
    await cubit.ensureMarket('1');
    now = now.add(const Duration(seconds: 30));
    await cubit.ensureClassification('7');

    now = now.add(const Duration(seconds: 30));
    await cubit.ensureMarket('1');
    await cubit.ensureClassification('7');

    expect(repository.marketCalls, 2);
    expect(repository.classificationCalls, 1);
  });

  test('failed market revalidation keeps loaded details and retries', () async {
    var now = DateTime.utc(2030, 1, 1, 12);
    final repository = _Repository();
    final cubit = StoreCubit(
      GetStoreUseCase(repository),
      getMarket: GetMarketUseCase(repository),
      getClassificationMarkets: GetClassificationMarketsUseCase(repository),
      now: () => now,
    );
    addTearDown(cubit.close);

    await cubit.loadStore();
    await cubit.ensureMarket('1');
    repository.failNextMarket = true;
    now = now.add(const Duration(seconds: 60));
    await cubit.ensureMarket('1');

    expect(cubit.state.data!.marketsFor('7').single.products, hasLength(4));
    await cubit.ensureMarket('1');
    expect(repository.marketCalls, 3);
  });

  test(
    'summary refresh preserves a fully loaded storefront when details fail',
    () async {
      var now = DateTime.utc(2030, 1, 1, 12);
      final repository = _Repository();
      final cubit = StoreCubit(
        GetStoreUseCase(repository),
        getMarket: GetMarketUseCase(repository),
        getClassificationMarkets: GetClassificationMarketsUseCase(repository),
        now: () => now,
      );
      addTearDown(cubit.close);

      await cubit.loadStore();
      await cubit.ensureMarket('1');
      repository.failNextMarket = true;
      now = now.add(const Duration(seconds: 60));
      await cubit.loadStore();

      expect(cubit.state.data!.marketsFor('7').single.products, hasLength(4));
    },
  );
}

class _Repository implements StoreRepository {
  int storeCalls = 0;
  int classificationCalls = 0;
  int marketCalls = 0;
  bool failNextMarket = false;
  Completer<ApiResult<StoreMarketData>>? pendingMarket;
  Completer<ApiResult<List<StoreMarketData>>>? pendingClassification;

  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async {
    storeCalls++;
    return ApiResult.success(
      StoreData(
        commonClassifications: const [],
        classifications: const [
          StoreClassificationData(
            id: '7',
            name: 'Restaurants',
            marketCount: 6,
            products: [],
            image: '',
            accentColorValue: 0xFF013C7E,
            classificationType: 'normal',
          ),
        ],
        marketsByClassificationId: {
          '7': [_market('1', productCount: 1)],
        },
      ),
    );
  }

  @override
  Future<ApiResult<List<StoreMarketData>>> getClassificationMarkets(
    String classificationId,
  ) async {
    classificationCalls++;
    if (pendingClassification case final completer?) return completer.future;
    return ApiResult.success(
      List.generate(6, (index) => _market('${index + 1}', productCount: 1)),
    );
  }

  @override
  Future<ApiResult<StoreMarketData>> getMarket(String marketId) async {
    marketCalls++;
    if (pendingMarket case final completer?) return completer.future;
    if (failNextMarket) {
      failNextMarket = false;
      return const ApiResult.failure(NetworkFailure('offline'));
    }
    return ApiResult.success(_market(marketId, productCount: 4));
  }
}

StoreMarketData _market(String id, {required int productCount}) {
  return StoreMarketData(
    id: id,
    name: 'Store $id',
    branch: '',
    status: 'active',
    classificationId: '7',
    products: List.generate(
      productCount,
      (index) =>
          ProductData.fromJson({'id': '$id-$index', 'name': 'Product $index'}),
    ),
    image: '',
    accentColorValue: 0xFF013C7E,
  );
}
