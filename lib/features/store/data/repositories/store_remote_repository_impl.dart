import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../location/data/datasources/location_preferences.dart';
import '../../domain/entities/product_data.dart';
import '../../domain/entities/store_data.dart';
import '../../domain/repositories/store_repository.dart';

class StoreRemoteRepositoryImpl implements StoreRepository {
  StoreRemoteRepositoryImpl(this._apiClient, [this._locationPreferences]);

  final ApiClient _apiClient;
  final LocationPreferences? _locationPreferences;

  @override
  Future<ApiResult<StoreData>> getStore() {
    return _guard(() async {
      final summary = await _apiClient.get<Map<String, dynamic>>(
        '/home/classifications/',
        queryParameters: await _cityQuery(),
      );
      final commonClassifications = _classificationsFromPayload(
        summary['common_categories'],
      );
      final classifications = _classificationsFromPayload(
        summary['market_classifications'],
      );
      final marketsByClassificationId = <String, List<StoreMarketData>>{};

      for (final classification in classifications) {
        marketsByClassificationId[classification.id] =
            await _loadClassificationMarkets(classification.id);
      }

      return StoreData(
        commonClassifications: commonClassifications,
        classifications: classifications,
        marketsByClassificationId: marketsByClassificationId,
      );
    });
  }

  Future<List<StoreMarketData>> _loadClassificationMarkets(
    String classificationId,
  ) async {
    if (classificationId.trim().isEmpty) return const [];

    final payload = await _apiClient.get<Map<String, dynamic>>(
      '/home/classifications/$classificationId/markets/',
      queryParameters: await _cityQuery(),
    );
    final markets = _marketsFromPayload(payload['markets']);
    final hydratedMarkets = <StoreMarketData>[];

    for (final market in markets) {
      final products = await _loadMarketProducts(market);
      hydratedMarkets.add(
        products.isEmpty ? market : market.copyWithProducts(products),
      );
    }

    return hydratedMarkets;
  }

  Future<List<ProductData>> _loadMarketProducts(StoreMarketData market) async {
    final query = market.name.trim();
    if (query.isEmpty) return const [];

    final payload = await _apiClient.get<Object?>(
      '/home/search/',
      queryParameters: {'q': query, ...await _cityQuery()},
    );
    final products = _productsFromPayload(payload);
    final filtered = products
        .where((product) => product.marketId == market.id)
        .toList(growable: false);

    return filtered.isEmpty ? products : filtered;
  }

  List<StoreClassificationData> _classificationsFromPayload(Object? payload) {
    if (payload is! List) return const [];
    return payload
        .whereType<Map<String, dynamic>>()
        .map(StoreClassificationData.fromJson)
        .toList(growable: false);
  }

  List<StoreMarketData> _marketsFromPayload(Object? payload) {
    if (payload is! List) return const [];
    return payload
        .whereType<Map<String, dynamic>>()
        .map(StoreMarketData.fromJson)
        .toList(growable: false);
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

  Future<Map<String, dynamic>> _cityQuery() async {
    final citySlug = await _locationPreferences?.getSelectedCitySlug();
    if (citySlug == null || citySlug.trim().isEmpty) return const {};
    final normalizedCity = citySlug.trim().toLowerCase();
    if (normalizedCity == 'general') return const {};
    return {'city': normalizedCity};
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load store data.'),
      );
    }
  }
}
