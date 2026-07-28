import '../../../../core/network/api_result.dart';
import '../../../store/domain/entities/store_data.dart';

abstract class MarketWishlistRepository {
  Future<ApiResult<List<StoreMarketData>>> getItems();

  Future<ApiResult<bool>> setFavorite(String marketId, bool favorite);
}
