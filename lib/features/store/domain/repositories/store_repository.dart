import '../../../../core/network/api_result.dart';
import '../entities/store_data.dart';

abstract class StoreRepository {
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false});

  Future<ApiResult<StoreMarketData>> getMarket(String marketId);

  Future<ApiResult<List<StoreMarketData>>> getClassificationMarkets(
    String classificationId,
  );
}
