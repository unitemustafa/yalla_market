import '../../../../core/network/api_result.dart';
import '../entities/store_data.dart';
import '../repositories/store_repository.dart';

class GetStoreUseCase {
  const GetStoreUseCase(this._repository);

  final StoreRepository _repository;

  Future<ApiResult<StoreData>> call({bool forceRefresh = false}) {
    return _repository.getStore(forceRefresh: forceRefresh);
  }
}
