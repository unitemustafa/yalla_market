import '../../../../core/domain/favorite_page.dart';
import '../../../../core/network/api_result.dart';
import '../entities/wishlist_item.dart';

abstract class WishlistRepository {
  Future<ApiResult<List<WishlistItem>>> getItems(String userKey);

  Future<ApiResult<List<WishlistItem>>> toggleItem(
    String userKey,
    WishlistItem item,
  );
}

abstract interface class PagedWishlistRepository {
  Future<ApiResult<FavoritePage<WishlistItem>>> getPage(
    String userKey, {
    int page = 1,
  });
}
