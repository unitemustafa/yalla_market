import '../../../../core/domain/favorite_page.dart';
import '../../../../core/network/api_result.dart';
import '../../../store/domain/entities/store_data.dart';
import '../repositories/market_wishlist_repository.dart';

class MarketWishlistUseCases {
  const MarketWishlistUseCases(this._repository);

  final MarketWishlistRepository _repository;

  bool get supportsPaging => _repository is PagedMarketWishlistRepository;
  Future<ApiResult<FavoritePage<StoreMarketData>>> page({int page = 1}) async {
    final repository = _repository;
    if (repository is PagedMarketWishlistRepository) {
      return (repository as PagedMarketWishlistRepository).getPage(page: page);
    }
    final result = await getItems();
    return result.when(
      success: (items) => ApiResult.success(
        FavoritePage(
          items: items,
          count: items.length,
          hasMore: false,
          favoriteIds: Set.unmodifiable(items.map((i) => i.id)),
        ),
      ),
      failure: ApiResult.failure,
    );
  }

  Future<ApiResult<List<StoreMarketData>>> getItems() {
    return _repository.getItems();
  }

  Future<ApiResult<bool>> setFavorite(String marketId, bool favorite) {
    return _repository.setFavorite(marketId, favorite);
  }
}
