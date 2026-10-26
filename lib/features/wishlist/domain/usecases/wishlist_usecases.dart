import '../../../../core/domain/favorite_page.dart';
import '../../../../core/network/api_result.dart';
import '../entities/wishlist_item.dart';
import '../repositories/wishlist_repository.dart';

class WishlistUseCases {
  const WishlistUseCases({required this.getItems, required this.toggleItem});

  final GetWishlistItemsUseCase getItems;
  final ToggleWishlistItemUseCase toggleItem;
}

class GetWishlistItemsUseCase {
  const GetWishlistItemsUseCase(this._repository);

  final WishlistRepository _repository;

  bool get supportsPaging => _repository is PagedWishlistRepository;
  Future<ApiResult<FavoritePage<WishlistItem>>> page(
    String userKey, {
    int page = 1,
  }) async {
    final repository = _repository;
    if (repository is PagedWishlistRepository) {
      return (repository as PagedWishlistRepository).getPage(
        userKey,
        page: page,
      );
    }
    final result = await call(userKey);
    return result.when(
      success: (items) => ApiResult.success(
        FavoritePage(
          items: items,
          count: items.length,
          hasMore: false,
          favoriteIds: Set.unmodifiable(items.map((i) => i.productId)),
        ),
      ),
      failure: ApiResult.failure,
    );
  }

  Future<ApiResult<List<WishlistItem>>> call(String userKey) {
    return _repository.getItems(userKey);
  }
}

class ToggleWishlistItemUseCase {
  const ToggleWishlistItemUseCase(this._repository);

  final WishlistRepository _repository;

  Future<ApiResult<List<WishlistItem>>> call(
    String userKey,
    WishlistItem item,
  ) {
    return _repository.toggleItem(userKey, item);
  }
}
