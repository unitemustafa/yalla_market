import '../../../../core/network/api_result.dart';
import '../../domain/entities/delivery_area.dart';
import '../../domain/repositories/delivery_area_repository.dart';

class DeliveryAreaRepositoryImpl implements DeliveryAreaRepository {
  @override
  Future<ApiResult<List<DeliveryArea>>> getDeliveryAreas(
    int serviceCityId,
  ) async {
    return ApiResult.success(
      _demoAreas
          .where((area) => area.serviceCityId == serviceCityId)
          .toList(growable: false),
    );
  }
}

const _demoAreas = [
  DeliveryArea(
    id: 1,
    serviceCityId: 1,
    name: 'Nasr City',
    deliveryPrice: 50,
    isActive: true,
  ),
  DeliveryArea(
    id: 2,
    serviceCityId: 1,
    name: 'New Cairo',
    deliveryPrice: 65,
    isActive: true,
  ),
];
