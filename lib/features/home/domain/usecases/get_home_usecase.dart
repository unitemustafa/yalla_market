import '../../../../core/network/api_result.dart';
import '../entities/home_data.dart';
import '../repositories/home_repository.dart';

class GetHomeUseCase {
  const GetHomeUseCase(this._repository);

  final HomeRepository _repository;

  Future<ApiResult<HomeData>> call({bool forceRefresh = false}) {
    return _repository.getHome(forceRefresh: forceRefresh);
  }
}
