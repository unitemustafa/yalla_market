import 'package:dio/dio.dart';

import '../../../../core/errors/address_required_error.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/region_required_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRemoteRepositoryImpl implements HomeRepository {
  HomeRemoteRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<HomeData>> getHome() {
    return _guard(() async {
      final payload = await _apiClient.get<Map<String, dynamic>>('/home/');
      return HomeData.fromJson(payload);
    });
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      if (isRegionRequiredPayload(error.response?.data)) {
        return const ApiResult.failure(
          ValidationFailure(regionRequiredMessage),
        );
      }
      if (isAddressRequiredError(error)) {
        return const ApiResult.failure(
          ValidationFailure(addressRequiredMessage),
        );
      }
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load home data.'),
      );
    }
  }
}
