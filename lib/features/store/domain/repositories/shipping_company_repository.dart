import '../../../../core/network/api_result.dart';
import '../entities/shipping_company.dart';

abstract class ShippingCompanyRepository {
  Future<ApiResult<List<ShippingCompanyData>>> getForCity(int serviceCityId);
}
