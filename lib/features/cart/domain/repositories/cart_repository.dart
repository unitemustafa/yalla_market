import '../../../../core/network/api_result.dart';
import '../entities/cart_item.dart';

abstract class CartRepository {
  Future<ApiResult<List<CartItemData>>> getItems(String userKey);

  Future<ApiResult<List<CartItemData>>> addItem(
    String userKey,
    CartItemData item,
    int quantityToAdd,
  );

  Future<ApiResult<List<CartItemData>>> incrementQuantity(
    String userKey,
    String id,
  );

  Future<ApiResult<List<CartItemData>>> decrementQuantity(
    String userKey,
    String id,
  );

  Future<ApiResult<List<CartItemData>>> removeItem(String userKey, String id);

  Future<ApiResult<List<CartItemData>>> clear(String userKey);
}
