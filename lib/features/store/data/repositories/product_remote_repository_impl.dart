import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../location/data/datasources/location_preferences.dart';
import '../../domain/entities/brand_data.dart';
import '../../domain/entities/category_data.dart';
import '../../domain/entities/product_data.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRemoteRepositoryImpl implements ProductRepository {
  ProductRemoteRepositoryImpl(this._apiClient, [this._locationPreferences]);

  final ApiClient _apiClient;
  final LocationPreferences? _locationPreferences;

  @override
  Future<ApiResult<List<ProductData>>> getProducts({String? citySlug}) {
    return _guard(() async {
      final payload = await _apiClient.get<Object?>(
        '/home/',
        queryParameters: await _cityQuery(citySlug),
      );
      return _productsFromPayload(payload);
    });
  }

  @override
  Future<ApiResult<ProductData>> getProduct(String idOrSlug) {
    return _guard(() async {
      final payload = await _apiClient.get<Map<String, dynamic>>(
        '/home/products/$idOrSlug/',
        queryParameters: await _cityQuery(null),
      );
      return ProductData.fromJson(payload);
    });
  }

  @override
  Future<ApiResult<List<ProductData>>> searchProducts(
    String query, {
    String? citySlug,
  }) {
    return _guard(() async {
      final payload = await _apiClient.get<Object?>(
        '/home/search/',
        queryParameters: {'q': query.trim(), ...await _cityQuery(citySlug)},
      );
      return _productsFromPayload(payload);
    });
  }

  @override
  Future<ApiResult<List<CategoryData>>> getCategories() {
    return _guard(() async {
      final payload = await _apiClient.get<Object?>(
        '/home/classifications/',
        queryParameters: await _cityQuery(null),
      );
      return _categoriesFromPayload(payload);
    });
  }

  @override
  Future<ApiResult<List<BrandData>>> getBrands() {
    return _guard(() async {
      final payload = await _apiClient.get<Object?>(
        '/home/classifications/',
        queryParameters: await _cityQuery(null),
      );
      return _brandsFromPayload(payload);
    });
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

  Future<Map<String, dynamic>> _cityQuery(String? explicitCitySlug) async {
    final citySlug =
        explicitCitySlug ?? await _locationPreferences?.getSelectedCitySlug();
    if (citySlug == null || citySlug.trim().isEmpty) return const {};
    return {'city': citySlug.trim()};
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load products.'),
      );
    }
  }
}
