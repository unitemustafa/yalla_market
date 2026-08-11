import '../../../../core/network/api_result.dart';
import '../../../store/domain/entities/store_data.dart';
import '../repositories/market_wishlist_repository.dart';

class MarketWishlistUseCases {
  const MarketWishlistUseCases(this._repository);

  final MarketWishlistRepository _repository;

  Future<ApiResult<List<StoreMarketData>>> getItems() {
    return _repository.getItems();
  }

  Future<ApiResult<bool>> setFavorite(String marketId, bool favorite) {
    return _repository.setFavorite(marketId, favorite);
  }
}
