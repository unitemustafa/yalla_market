import '../../../../core/network/api_result.dart';
import '../entities/partner_application.dart';

abstract class PartnerApplicationRepository {
  Future<ApiResult<PartnerApplicationReceipt>> submit(
    PartnerApplicationRequest request,
  );
}
