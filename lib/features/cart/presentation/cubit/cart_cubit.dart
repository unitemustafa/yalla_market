import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/usecases/cart_usecases.dart';

class CartCubit extends Cubit<List<CartItemData>> {
  CartCubit(this._cartUseCases) : super(const []);

  final CartUseCases _cartUseCases;
  String? _currentUserKey;
  int _generation = 0;

  String? lastErrorMessage;

  bool get usesRemoteCart => false;

  Future<void> loadCartForUser(String userKey) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      clearSession();
      return;
    }

    if (_currentUserKey != normalizedUserKey) {
      _generation++;
      _currentUserKey = normalizedUserKey;
      lastErrorMessage = null;
      emit(const []);
    }
    final generation = _generation;
    final result = await _cartUseCases.getItems(normalizedUserKey);
    _emitResult(result, normalizedUserKey, generation);
  }

  Future<void> addItem(CartItemData newItem, int quantityToAdd) async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final generation = _generation;
    final result = await _cartUseCases.addItem(userKey, newItem, quantityToAdd);
    _emitResult(result, userKey, generation);
  }

  Future<void> incrementQuantity(String id) async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final generation = _generation;
    final result = await _cartUseCases.incrementQuantity(userKey, id);
    _emitResult(result, userKey, generation);
  }

  Future<void> decrementQuantity(String id) async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final generation = _generation;
    final result = await _cartUseCases.decrementQuantity(userKey, id);
    _emitResult(result, userKey, generation);
  }

  Future<void> removeItem(String id) async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final generation = _generation;
    final result = await _cartUseCases.removeItem(userKey, id);
    _emitResult(result, userKey, generation);
  }

  Future<bool> clearLocalCart() async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) {
      clearSession();
      return true;
    }

    final generation = _generation;
    final result = await _cartUseCases.clearCart(userKey);
    if (!_isCurrent(userKey, generation)) return false;
    return result.when(
      success: (items) {
        lastErrorMessage = null;
        emit(items);
        return true;
      },
      failure: (failure) {
        lastErrorMessage = failure.message;
        return false;
      },
    );
  }

  void clearSession() {
    _generation++;
    _currentUserKey = null;
    lastErrorMessage = null;
    emit(const []);
  }

  void _emitResult(
    ApiResult<List<CartItemData>> result,
    String userKey,
    int generation,
  ) {
    if (!_isCurrent(userKey, generation)) return;
    result.when(
      success: (items) {
        lastErrorMessage = null;
        emit(items);
      },
      failure: (failure) {
        lastErrorMessage = failure.message;
      },
    );
  }

  bool _isCurrent(String userKey, int generation) =>
      generation == _generation && _currentUserKey == userKey && !isClosed;
}
