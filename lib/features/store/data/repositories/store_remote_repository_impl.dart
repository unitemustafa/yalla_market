import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/cache/persistent_json_cache.dart';
import '../../../../core/errors/address_required_error.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/region_required_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../location/domain/usecases/location_usecases.dart';
import '../../domain/entities/store_data.dart';
import '../../domain/repositories/store_repository.dart';

class StoreRemoteRepositoryImpl implements StoreRepository {
  StoreRemoteRepositoryImpl(
    this._apiClient, {
    PersistentJsonCache? cache,
    GetSelectedCityUseCase? getSelectedCity,
  }) : _cache = cache,
       _getSelectedCity = getSelectedCity;

  final ApiClient _apiClient;
  final PersistentJsonCache? _cache;
  final GetSelectedCityUseCase? _getSelectedCity;
  static const _freshness = Duration(minutes: 30);

  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async {
    final key = 'store.${await _scope()}';
    final cached = await _cache?.read(key);
    final cachedStore = _storeFromCache(cached);

    if (!forceRefresh && cachedStore != null && cached!.isFresh(_freshness)) {
      unawaited(_refreshCache(key));
      return ApiResult.success(cachedStore);
    }

    try {
      return ApiResult.success(await _fetchAndCache(key));
    } on DioException catch (error) {
      if (cachedStore != null && _canUseCache(error)) {
        return ApiResult.success(cachedStore);
      }
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
      if (cachedStore != null) return ApiResult.success(cachedStore);
      return const ApiResult.failure(
        UnknownFailure('Could not load store data.'),
      );
    }
  }

  Future<StoreData> _fetchAndCache(String key) async {
    final summary = await _apiClient.get<Map<String, dynamic>>(
      '/home/classifications/',
    );
    await _cache?.write(key, summary);
    return _storeFromSummary(summary);
  }

  Future<void> _refreshCache(String key) async {
    try {
      await _fetchAndCache(key);
    } catch (_) {
      // Keep the last valid snapshot until the next explicit refresh.
    }
  }

  StoreData? _storeFromCache(CachedJsonEntry? entry) {
    final value = entry?.value;
    if (value is! Map<String, dynamic>) return null;
    try {
      return _storeFromSummary(value);
    } catch (_) {
      return null;
    }
  }

  StoreData _storeFromSummary(Map<String, dynamic> summary) {
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
    return StoreData(
      commonClassifications: commonClassifications,
      classifications: classifications,
      marketsByClassificationId: marketsByClassificationId,
      latestMarkets: _marketsFromPayload(summary['latest_markets']),
    );
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

  Future<String> _scope() async {
    final useCase = _getSelectedCity;
    if (useCase == null) return 'general';
    final result = await useCase();
    return result.when(
      success: (city) => city?.slug.trim().toLowerCase() ?? 'general',
      failure: (_) => 'general',
    );
  }

  bool _canUseCache(DioException error) {
    final status = error.response?.statusCode;
    return error.response == null || (status != null && status >= 500);
  }
}
