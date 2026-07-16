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
import '../../domain/entities/brand_data.dart';
import '../../domain/entities/category_data.dart';
import '../../domain/entities/product_data.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRemoteRepositoryImpl implements ProductRepository {
  ProductRemoteRepositoryImpl(
    this._apiClient, {
    PersistentJsonCache? cache,
    GetSelectedCityUseCase? getSelectedCity,
  }) : _cache = cache,
       _getSelectedCity = getSelectedCity;

  final ApiClient _apiClient;
  final PersistentJsonCache? _cache;
  final GetSelectedCityUseCase? _getSelectedCity;
  Future<Object?>? _classificationsInFlight;
  static const _listFreshness = Duration(minutes: 30);
  static const _detailFreshness = Duration(minutes: 20);

  @override
  Future<ApiResult<List<ProductData>>> getProducts({
    String? citySlug,
    bool forceRefresh = false,
  }) async {
    final scope = await _scope(citySlug);
    return _cachedRequest<List<ProductData>>(
      key: 'products.$scope',
      forceRefresh: forceRefresh,
      freshness: _listFreshness,
      fetch: () => _apiClient.get<Object?>(
        '/home/products/',
        queryParameters: const {'order_by_latest': true, 'page_size': 15},
      ),
      parse: _productsFromPayload,
      errorMessage: 'Could not load products.',
    );
  }

  @override
  Future<ApiResult<ProductData>> getProduct(String idOrSlug) async {
    final scope = await _scope(null);
    return _cachedRequest<ProductData>(
      key: 'product.$scope.$idOrSlug',
      forceRefresh: false,
      freshness: _detailFreshness,
      fetch: () =>
          _apiClient.get<Map<String, dynamic>>('/home/products/$idOrSlug/'),
      parse: (payload) {
        if (payload is! Map<String, dynamic>) {
          throw const FormatException('Invalid product payload.');
        }
        return ProductData.fromJson(payload);
      },
      errorMessage: 'Could not load product.',
    );
  }

  @override
  Future<ApiResult<List<ProductData>>> searchProducts(
    String query, {
    String? citySlug,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return getProducts(citySlug: citySlug);
    final scope = await _scope(citySlug);
    final cached = await _cache?.read('products.$scope');
    try {
      final payload = await _apiClient.get<Object?>(
        '/home/search/',
        queryParameters: {'q': normalized},
      );
      return ApiResult.success(_productsFromPayload(payload));
    } on DioException catch (error) {
      if (_canUseCache(error)) {
        final cachedProducts = _productsFromCache(cached);
        if (cachedProducts != null) {
          return ApiResult.success(
            cachedProducts
                .where((product) => product.matches(normalized))
                .toList(growable: false),
          );
        }
      }
      return _failureForDio(error);
    } catch (_) {
      final cachedProducts = _productsFromCache(cached);
      if (cachedProducts != null) {
        return ApiResult.success(
          cachedProducts
              .where((product) => product.matches(normalized))
              .toList(growable: false),
        );
      }
      return const ApiResult.failure(
        UnknownFailure('Could not search products.'),
      );
    }
  }

  @override
  Future<ApiResult<List<CategoryData>>> getCategories({
    bool forceRefresh = false,
  }) async {
    final scope = await _scope(null);
    return _cachedRequest<List<CategoryData>>(
      key: 'classifications.$scope',
      forceRefresh: forceRefresh,
      freshness: _listFreshness,
      fetch: _getClassificationsPayload,
      parse: _categoriesFromPayload,
      errorMessage: 'Could not load categories.',
    );
  }

  @override
  Future<ApiResult<List<BrandData>>> getBrands({
    bool forceRefresh = false,
  }) async {
    final scope = await _scope(null);
    return _cachedRequest<List<BrandData>>(
      key: 'classifications.$scope',
      forceRefresh: forceRefresh,
      freshness: _listFreshness,
      fetch: _getClassificationsPayload,
      parse: _brandsFromPayload,
      errorMessage: 'Could not load brands.',
    );
  }

  Future<Object?> _getClassificationsPayload() async {
    final existing = _classificationsInFlight;
    if (existing != null) return existing;

    final operation = _apiClient.get<Object?>('/home/classifications/');
    _classificationsInFlight = operation;
    try {
      return await operation;
    } finally {
      if (identical(_classificationsInFlight, operation)) {
        _classificationsInFlight = null;
      }
    }
  }

  List<ProductData> _productsFromPayload(Object? payload) {
    final rawItems = payload is Map<String, dynamic>
        ? payload['results'] ?? payload['items'] ?? payload['products']
        : payload;
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(ProductData.fromJson)
        .toList(growable: false);
  }

  List<CategoryData> _categoriesFromPayload(Object? payload) {
    final rawItems = payload is Map<String, dynamic>
        ? payload['common_categories'] ??
              payload['market_classifications'] ??
              payload['items'] ??
              payload['categories']
        : payload;
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(CategoryData.fromJson)
        .toList(growable: false);
  }

  List<BrandData> _brandsFromPayload(Object? payload) {
    final rawItems = payload is Map<String, dynamic>
        ? payload['common_categories'] ??
              payload['market_classifications'] ??
              payload['items'] ??
              payload['brands']
        : payload;
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(BrandData.fromJson)
        .toList(growable: false);
  }

  Future<ApiResult<T>> _cachedRequest<T>({
    required String key,
    required bool forceRefresh,
    required Duration freshness,
    required Future<Object?> Function() fetch,
    required T Function(Object? payload) parse,
    required String errorMessage,
  }) async {
    final cached = await _cache?.read(key);
    final cachedValue = _parseCache(cached, parse);

    if (!forceRefresh && cachedValue != null && cached!.isFresh(freshness)) {
      unawaited(_refreshCache(key, fetch));
      return ApiResult.success(cachedValue);
    }

    try {
      final payload = await fetch();
      final parsed = parse(payload);
      await _cache?.write(key, payload);
      return ApiResult.success(parsed);
    } on DioException catch (error) {
      if (cachedValue != null && _canUseCache(error)) {
        return ApiResult.success(cachedValue);
      }
      return _failureForDio(error);
    } catch (_) {
      if (cachedValue != null) return ApiResult.success(cachedValue);
      return ApiResult.failure(UnknownFailure(errorMessage));
    }
  }

  Future<void> _refreshCache(
    String key,
    Future<Object?> Function() fetch,
  ) async {
    try {
      final payload = await fetch();
      await _cache?.write(key, payload);
    } catch (_) {
      // Keep serving the previous snapshot until an explicit refresh succeeds.
    }
  }

  T? _parseCache<T>(CachedJsonEntry? cached, T Function(Object?) parse) {
    if (cached == null) return null;
    try {
      return parse(cached.value);
    } catch (_) {
      return null;
    }
  }

  List<ProductData>? _productsFromCache(CachedJsonEntry? cached) {
    return _parseCache(cached, _productsFromPayload);
  }

  ApiResult<T> _failureForDio<T>(DioException error) {
    if (isRegionRequiredPayload(error.response?.data)) {
      return const ApiResult.failure(ValidationFailure(regionRequiredMessage));
    }
    if (isAddressRequiredError(error)) {
      return const ApiResult.failure(ValidationFailure(addressRequiredMessage));
    }
    return ApiResult.failure(ApiErrorHandler.handle(error));
  }

  Future<String> _scope(String? citySlug) async {
    final explicit = citySlug?.trim().toLowerCase();
    if (explicit != null && explicit.isNotEmpty) return explicit;
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
