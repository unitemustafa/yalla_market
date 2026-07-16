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
import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRemoteRepositoryImpl implements HomeRepository {
  HomeRemoteRepositoryImpl(
    this._apiClient, {
    PersistentJsonCache? cache,
    GetSelectedCityUseCase? getSelectedCity,
  }) : _cache = cache,
       _getSelectedCity = getSelectedCity;

  final ApiClient _apiClient;
  final PersistentJsonCache? _cache;
  final GetSelectedCityUseCase? _getSelectedCity;
  static const _freshness = Duration(minutes: 15);

  @override
  Future<ApiResult<HomeData>> getHome({bool forceRefresh = false}) async {
    final key = 'home.${await _scope()}';
    final cached = await _cache?.read(key);
    final cachedHome = _homeFromCache(cached);

    if (!forceRefresh && cachedHome != null && cached!.isFresh(_freshness)) {
      unawaited(_refreshCache(key));
      return ApiResult.success(cachedHome);
    }

    try {
      return ApiResult.success(await _fetchAndCache(key));
    } on DioException catch (error) {
      if (cachedHome != null && _canUseCache(error)) {
        return ApiResult.success(cachedHome);
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
      if (cachedHome != null) return ApiResult.success(cachedHome);
      return const ApiResult.failure(
        UnknownFailure('Could not load home data.'),
      );
    }
  }

  Future<HomeData> _fetchAndCache(String key) async {
    final payload = await _apiClient.get<Map<String, dynamic>>('/home/');
    final cachePayload = <String, dynamic>{...payload, 'location': null};
    await _cache?.write(key, cachePayload);
    return HomeData.fromJson(payload);
  }

  Future<void> _refreshCache(String key) async {
    try {
      await _fetchAndCache(key);
    } catch (_) {
      // The cached snapshot stays visible; manual refresh still reports errors.
    }
  }

  HomeData? _homeFromCache(CachedJsonEntry? entry) {
    final value = entry?.value;
    if (value is! Map<String, dynamic>) return null;
    try {
      return HomeData.fromJson(value);
    } catch (_) {
      return null;
    }
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
