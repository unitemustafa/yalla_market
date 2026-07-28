import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../store/domain/entities/store_data.dart';
import '../../domain/repositories/market_wishlist_repository.dart';

class MarketWishlistRemoteRepository implements MarketWishlistRepository {
  const MarketWishlistRemoteRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<List<StoreMarketData>>> getItems() {
    return _guard(() async {
      final payload = await _apiClient.get<Object?>('/home/markets/likes/');
      final rawItems = payload is Map<String, dynamic>
          ? payload['results'] ?? payload['markets'] ?? payload['items']
          : payload;
      if (rawItems is! List) return const <StoreMarketData>[];
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(StoreMarketData.fromJson)
          .where((market) => market.id.isNotEmpty)
          .toList(growable: false);
    });
  }

  @override
  Future<ApiResult<bool>> setFavorite(String marketId, bool favorite) {
    return _guard(() async {
      final payload = favorite
          ? await _apiClient.post<Object?>('/home/markets/$marketId/like/')
          : await _apiClient.delete<Object?>('/home/markets/$marketId/unlike/');
      if (payload is Map<String, dynamic> && payload['liked'] is bool) {
        return payload['liked'] as bool;
      }
      return favorite;
    });
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not update favorite stores.'),
      );
    }
  }
}
