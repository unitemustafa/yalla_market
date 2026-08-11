import 'package:flutter_test/flutter_test.dart';
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
}

class _Repository implements StoreRepository {
  int classificationCalls = 0;
  int marketCalls = 0;

  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async {
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
    return ApiResult.success(
      List.generate(6, (index) => _market('${index + 1}', productCount: 1)),
    );
  }

  @override
  Future<ApiResult<StoreMarketData>> getMarket(String marketId) async {
    marketCalls++;
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
