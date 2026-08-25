import '../../../../core/network/api_result.dart';
import '../entities/shipping_company.dart';
import '../repositories/shipping_company_repository.dart';

class GetShippingCompaniesUseCase {
  const GetShippingCompaniesUseCase(this._repository);

  final ShippingCompanyRepository _repository;

  Future<ApiResult<List<ShippingCompanyData>>> call(int serviceCityId) {
    return _repository.getForCity(serviceCityId);
  }
}
