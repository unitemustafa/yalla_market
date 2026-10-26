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
import '../mapping/storefront_decoder.dart';
import '../../../../core/domain/data_page.dart';
import '../../domain/usecases/get_market_listing_usecase.dart';

class StoreRemoteRepositoryImpl
    implements StoreRepository, MarketListingRepository {
  StoreRemoteRepositoryImpl(
    this._apiClient, {
    PersistentJsonCache? cache,
    GetSelectedCityUseCase? getSelectedCity,
    StorefrontDecoder decoder = const StorefrontDecoder(),
  }) : _cache = cache,
       _getSelectedCity = getSelectedCity,
       _decoder = decoder;

  final StorefrontDecoder _decoder;

  final ApiClient _apiClient;
  final PersistentJsonCache? _cache;
  final GetSelectedCityUseCase? _getSelectedCity;
  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async {
    final key = 'store.v6.${await _scope()}';
    final cached = forceRefresh ? null : await _cache?.read(key);
    final cachedStore = _storeFromCache(cached);

    if (!forceRefresh && cachedStore != null) {
      return ApiResult.success(
        cachedStore,
        origin: DataOrigin.cache,
        savedAt: cached!.savedAt,
      );
    }

    try {
      return ApiResult.success(await _fetchAndCache(key));
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

  @override
  Future<ApiResult<StoreMarketData>> getMarket(String marketId) async {
    try {
      final payload = await _apiClient.get<Map<String, dynamic>>(
        '/home/markets/$marketId/storefront/',
        queryParameters: const {'include_products': false},
      );
      return ApiResult.success(await _decoder.decode(payload));
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load store details.'),
      );
    }
  }

  @override
  Future<ApiResult<List<StoreMarketData>>> getClassificationMarkets(
    String classificationId,
  ) async {
    try {
      final payload = await _apiClient.get<Map<String, dynamic>>(
        '/home/classifications/$classificationId/markets/',
      );
      return ApiResult.success(_marketsFromPayload(payload['markets']));
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load category stores.'),
      );
    }
  }

  Future<StoreData> _fetchAndCache(String key) async {
    final summary = await _apiClient.get<Map<String, dynamic>>(
      '/home/classifications/',
      queryParameters: const {'include_products': false},
    );
    await _cache?.write(key, summary);
    return _storeFromSummary(summary);
  }

  @override
  Future<ApiResult<DataPage<StoreMarketData>>> getMarketPage(
    MarketListingQuery query, {
    int page = 1,
  }) async {
    try {
      final payload = await _apiClient.get<Map<String, dynamic>>(
        '/home/store-list/',
        queryParameters: {
          'page': page,
          'page_size': 30,
          'q': query.query,
          if (query.classificationId.isNotEmpty)
            'classification_id': query.classificationId,
          if (query.typeId != null) 'market_type_id': query.typeId,
          'popular': query.popular,
          'latest': query.latest,
        },
      );
      final raw = payload['results'];
      final count = payload['count'];
      final next = payload['next'];
      if (raw is! List ||
          raw.length > 30 ||
          count is! int ||
          count < 0 ||
          (next != null && next is! String) ||
          raw.any(
            (item) =>
                item is! Map<String, dynamic> ||
                (item['id']?.toString() ?? '').isEmpty,
          )) {
        throw const FormatException('Invalid market page');
      }
      return ApiResult.success(
        MarketListingPage(
          items: List.unmodifiable(_marketsFromPayload(raw)),
          count: count,
          hasMore: next != null,
          types: List.unmodifiable(
            _jsonMaps(
              payload['market_types'],
            ).map(StoreMarketTypeData.fromJson),
          ),
          selectedTypeId: payload['selected_type_id']?.toString(),
          totalCount: payload['total_count'] is int
              ? payload['total_count'] as int
              : count,
        ),
      );
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(UnknownFailure('Could not load stores.'));
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
      popularMarkets: summary['popular_markets'] is List
          ? _marketsFromPayload(summary['popular_markets'])
          : null,
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
}
