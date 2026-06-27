import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../location/data/datasources/location_preferences.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRemoteRepositoryImpl implements HomeRepository {
  HomeRemoteRepositoryImpl(this._apiClient, [this._locationPreferences]);

  final ApiClient _apiClient;
  final LocationPreferences? _locationPreferences;

  @override
  Future<ApiResult<HomeData>> getHome() {
    return _guard(() async {
      final citySlug = await _locationPreferences?.getSelectedCitySlug();
      final payload = await _apiClient.get<Map<String, dynamic>>(
        '/home/',
        queryParameters: {
          if (citySlug != null && citySlug.trim().isNotEmpty)
            'city': citySlug.trim(),
        },
      );
      return HomeData.fromJson(payload);
    });
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load home data.'),
      );
    }
  }
}
