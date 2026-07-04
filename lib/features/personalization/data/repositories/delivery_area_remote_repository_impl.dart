import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/delivery_area.dart';
import '../../domain/repositories/delivery_area_repository.dart';

class DeliveryAreaRemoteRepositoryImpl implements DeliveryAreaRepository {
  DeliveryAreaRemoteRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<List<DeliveryArea>>> getDeliveryAreas(int serviceCityId) {
    return _guard(() async {
      final payload = await _apiClient.get<Object?>(
        '/locations/delivery-areas/',
        queryParameters: {'service_city_id': serviceCityId},
      );
      return deliveryAreasFromPayload(payload);
    });
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load delivery areas.'),
      );
    }
  }
}

List<DeliveryArea> deliveryAreasFromPayload(Object? payload) {
  final rawItems = _listPayload(payload);
  if (rawItems is! List) return const [];
  return rawItems
      .whereType<Map<String, dynamic>>()
      .map(DeliveryArea.fromJson)
      .where((area) => area.isValid)
      .toList(growable: false);
}

Object? _listPayload(Object? payload) {
  if (payload is List) return payload;
  if (payload is Map<String, dynamic>) {
    final data = payload['data'];
    if (payload['results'] is List) return payload['results'];
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] is List) {
      return data['results'];
    }
  }
  return null;
}
