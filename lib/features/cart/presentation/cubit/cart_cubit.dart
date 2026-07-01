import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/usecases/cart_usecases.dart';

class CartCubit extends Cubit<List<CartItemData>> {
  CartCubit(this._cartUseCases) : super(const []);

  final CartUseCases _cartUseCases;
  String? _currentUserKey;

  String? lastErrorMessage;

  bool get usesRemoteCart => false;

  Future<void> loadCartForUser(String userKey) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      clearSession();
      return;
    }

    _currentUserKey = normalizedUserKey;
    final result = await _cartUseCases.getItems(normalizedUserKey);
    _emitResult(result);
  }

  Future<void> addItem(CartItemData newItem, int quantityToAdd) async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final result = await _cartUseCases.addItem(userKey, newItem, quantityToAdd);
    _emitResult(result);
  }

  Future<void> incrementQuantity(String id) async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final result = await _cartUseCases.incrementQuantity(userKey, id);
    _emitResult(result);
  }

  Future<void> decrementQuantity(String id) async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final result = await _cartUseCases.decrementQuantity(userKey, id);
    _emitResult(result);
  }

  Future<void> removeItem(String id) async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final result = await _cartUseCases.removeItem(userKey, id);
    _emitResult(result);
  }

  Future<void> clearLocalCart() async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) {
      clearSession();
      return;
    }

    final result = await _cartUseCases.clearCart(userKey);
    _emitResult(result);
  }

  void clearSession() {
    _currentUserKey = null;
    lastErrorMessage = null;
    emit(const []);
  }

  void _emitResult(ApiResult<List<CartItemData>> result) {
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
}
