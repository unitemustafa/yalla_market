import '../../../../core/network/api_result.dart';
import '../entities/delivery_area.dart';
import '../repositories/delivery_area_repository.dart';

class GetDeliveryAreasUseCase {
  const GetDeliveryAreasUseCase(this._repository);

  final DeliveryAreaRepository _repository;

  Future<ApiResult<List<DeliveryArea>>> call(int serviceCityId) {
    return _repository.getDeliveryAreas(serviceCityId);
  }
}
