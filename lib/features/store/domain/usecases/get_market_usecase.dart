import '../../../../core/network/api_result.dart';
import '../entities/store_data.dart';
import '../repositories/store_repository.dart';

class GetMarketUseCase {
  const GetMarketUseCase(this._repository);

  final StoreRepository _repository;

  Future<ApiResult<StoreMarketData>> call(String marketId) {
    return _repository.getMarket(marketId);
  }
}
