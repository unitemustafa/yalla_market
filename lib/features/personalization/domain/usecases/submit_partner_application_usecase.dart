import '../../../../core/network/api_result.dart';
import '../entities/partner_application.dart';
import '../repositories/partner_application_repository.dart';

class SubmitPartnerApplicationUseCase {
  const SubmitPartnerApplicationUseCase(this._repository);

  final PartnerApplicationRepository _repository;

  Future<ApiResult<PartnerApplicationReceipt>> call(
    PartnerApplicationRequest request,
  ) {
    return _repository.submit(request);
  }
}
