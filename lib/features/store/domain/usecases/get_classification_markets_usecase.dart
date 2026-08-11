import '../../../../core/network/api_result.dart';
import '../entities/store_data.dart';
import '../repositories/store_repository.dart';

class GetClassificationMarketsUseCase {
  const GetClassificationMarketsUseCase(this._repository);

  final StoreRepository _repository;

  Future<ApiResult<List<StoreMarketData>>> call(String classificationId) {
    return _repository.getClassificationMarkets(classificationId);
  }
}
