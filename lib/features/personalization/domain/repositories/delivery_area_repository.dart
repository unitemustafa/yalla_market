import '../../../../core/network/api_result.dart';
import '../entities/delivery_area.dart';

abstract class DeliveryAreaRepository {
  Future<ApiResult<List<DeliveryArea>>> getDeliveryAreas(int serviceCityId);
}
