import 'package:dio/dio.dart';

import '../../../../core/errors/address_required_error.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/region_required_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/store_data.dart';
import '../../domain/repositories/store_repository.dart';

class StoreRemoteRepositoryImpl implements StoreRepository {
  StoreRemoteRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<StoreData>> getStore() {
    return _guard(() async {
      final summary = await _apiClient.get<Map<String, dynamic>>(
        '/home/classifications/',
      );
      final classifications = _classificationsFromPayload(
        summary['market_classifications'],
      );
      final classificationsById = {
        for (final classification in classifications)
          classification.id: classification,
      };
      final commonClassifications =
          _jsonMaps(summary['common_market_classifications'])
              .map((raw) => classificationsById[raw['id']?.toString() ?? ''])
              .whereType<StoreClassificationData>()
              .toList(growable: false);
      final marketsByClassificationId = <String, List<StoreMarketData>>{
        for (final raw in _jsonMaps(summary['market_classifications']))
          if ((raw['id']?.toString() ?? '').isNotEmpty)
            raw['id'].toString(): _marketsFromPayload(raw['markets']),
      };
      final latestMarkets = _marketsFromPayload(summary['latest_markets']);

      return StoreData(
        commonClassifications: commonClassifications,
        classifications: classifications,
        marketsByClassificationId: marketsByClassificationId,
        latestMarkets: latestMarkets,
      );
    });
  }

  List<StoreClassificationData> _classificationsFromPayload(Object? payload) {
    return _jsonMaps(
      payload,
    ).map(StoreClassificationData.fromJson).toList(growable: false);
  }

  List<StoreMarketData> _marketsFromPayload(Object? payload) {
    return _jsonMaps(
      payload,
    ).map(StoreMarketData.fromJson).toList(growable: false);
  }

  List<Map<String, dynamic>> _jsonMaps(Object? payload) {
    if (payload is! List) return const [];
    return payload.whereType<Map<String, dynamic>>().toList(growable: false);
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
        UnknownFailure('Could not load store data.'),
      );
    }
  }
}
