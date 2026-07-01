import '../../../../core/network/api_result.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class CartUseCases {
  const CartUseCases({
    required this.getItems,
    required this.addItem,
    required this.incrementQuantity,
    required this.decrementQuantity,
    required this.removeItem,
    required this.clearCart,
  });

  final GetCartItemsUseCase getItems;
  final AddCartItemUseCase addItem;
  final IncrementCartItemQuantityUseCase incrementQuantity;
  final DecrementCartItemQuantityUseCase decrementQuantity;
  final RemoveCartItemUseCase removeItem;
  final ClearCartUseCase clearCart;
}

class GetCartItemsUseCase {
  const GetCartItemsUseCase(this._repository);

  final CartRepository _repository;

  Future<ApiResult<List<CartItemData>>> call(String userKey) {
    return _repository.getItems(userKey);
  }
}

class AddCartItemUseCase {
  const AddCartItemUseCase(this._repository);

  final CartRepository _repository;

  Future<ApiResult<List<CartItemData>>> call(
    String userKey,
    CartItemData item,
    int quantityToAdd,
  ) {
    return _repository.addItem(userKey, item, quantityToAdd);
  }
}

class IncrementCartItemQuantityUseCase {
  const IncrementCartItemQuantityUseCase(this._repository);

  final CartRepository _repository;

  Future<ApiResult<List<CartItemData>>> call(String userKey, String id) {
    return _repository.incrementQuantity(userKey, id);
  }
}

class DecrementCartItemQuantityUseCase {
  const DecrementCartItemQuantityUseCase(this._repository);

  final CartRepository _repository;

  Future<ApiResult<List<CartItemData>>> call(String userKey, String id) {
    return _repository.decrementQuantity(userKey, id);
  }
}

class RemoveCartItemUseCase {
  const RemoveCartItemUseCase(this._repository);

  final CartRepository _repository;

  Future<ApiResult<List<CartItemData>>> call(String userKey, String id) {
    return _repository.removeItem(userKey, id);
  }
}

class ClearCartUseCase {
  const ClearCartUseCase(this._repository);

  final CartRepository _repository;

  Future<ApiResult<List<CartItemData>>> call(String userKey) {
    return _repository.clear(userKey);
  }
}
