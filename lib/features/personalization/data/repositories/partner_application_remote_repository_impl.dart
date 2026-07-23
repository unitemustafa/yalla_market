import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/partner_application.dart';
import '../../domain/repositories/partner_application_repository.dart';

class PartnerApplicationRemoteRepositoryImpl
    implements PartnerApplicationRepository {
  PartnerApplicationRemoteRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<PartnerApplicationReceipt>> submit(
    PartnerApplicationRequest request,
  ) async {
    try {
      final payload = await _apiClient.post<Object?>(
        '/partners/applications/',
        data: request.toJson(),
      );
      if (payload is! Map<String, dynamic>) {
        return const ApiResult.failure(
          UnknownFailure('Partner application response was incomplete.'),
        );
      }
      return ApiResult.success(PartnerApplicationReceipt.fromJson(payload));
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not submit partner application.'),
      );
    }
  }
}
