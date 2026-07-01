import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  @override
  Future<ApiResult<List<CartItemData>>> getItems(String userKey) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      return const ApiResult.success([]);
    }

    final preferences = await SharedPreferences.getInstance();
    final items = await _readItems(preferences, normalizedUserKey);
    return ApiResult.success(List.unmodifiable(items));
  }

  @override
  Future<ApiResult<List<CartItemData>>> addItem(
    String userKey,
    CartItemData item,
    int quantityToAdd,
  ) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      return const ApiResult.failure(
        ValidationFailure('User is required for cart.'),
      );
    }

    if (quantityToAdd <= 0) {
      return const ApiResult.failure(
        ValidationFailure('Quantity must be greater than zero.'),
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final items = await _readItems(preferences, normalizedUserKey);
    final index = items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      items[index] = items[index].copyWith(
        quantity: items[index].quantity + quantityToAdd,
      );
    } else {
      items.add(item.copyWith(quantity: quantityToAdd));
    }

    await _saveItems(preferences, normalizedUserKey, items);
    return ApiResult.success(List.unmodifiable(items));
  }

  @override
  Future<ApiResult<List<CartItemData>>> incrementQuantity(
    String userKey,
    String id,
  ) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      return const ApiResult.failure(
        ValidationFailure('User is required for cart.'),
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final items = await _readItems(preferences, normalizedUserKey);
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) {
      return const ApiResult.failure(ValidationFailure('Cart item not found.'));
    }

    items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    await _saveItems(preferences, normalizedUserKey, items);
    return ApiResult.success(List.unmodifiable(items));
  }

  @override
  Future<ApiResult<List<CartItemData>>> decrementQuantity(
    String userKey,
    String id,
  ) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      return const ApiResult.failure(
        ValidationFailure('User is required for cart.'),
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final items = await _readItems(preferences, normalizedUserKey);
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) {
      return const ApiResult.failure(ValidationFailure('Cart item not found.'));
    }

    final currentQuantity = items[index].quantity;
    if (currentQuantity <= 1) {
      return ApiResult.success(List.unmodifiable(items));
    }

    items[index] = items[index].copyWith(quantity: currentQuantity - 1);
    await _saveItems(preferences, normalizedUserKey, items);
    return ApiResult.success(List.unmodifiable(items));
  }

  @override
  Future<ApiResult<List<CartItemData>>> removeItem(
    String userKey,
    String id,
  ) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      return const ApiResult.failure(
        ValidationFailure('User is required for cart.'),
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final items = await _readItems(preferences, normalizedUserKey)
      ..removeWhere((item) => item.id == id);
    await _saveItems(preferences, normalizedUserKey, items);
    return ApiResult.success(List.unmodifiable(items));
  }

  @override
  Future<ApiResult<List<CartItemData>>> clear(String userKey) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      return const ApiResult.failure(
        ValidationFailure('User is required for cart.'),
      );
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey(normalizedUserKey));
    return const ApiResult.success([]);
  }

  String _storageKey(String userKey) => 'cart_user_$userKey';

  Future<List<CartItemData>> _readItems(
    SharedPreferences preferences,
    String userKey,
  ) async {
    final key = _storageKey(userKey);
    final raw = preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CartItemData.fromJson)
          .where((item) => item.id.trim().isNotEmpty)
          .toList();
    } catch (_) {
      await preferences.remove(key);
      return [];
    }
  }

  Future<void> _saveItems(
    SharedPreferences preferences,
    String userKey,
    List<CartItemData> items,
  ) {
    return preferences.setString(
      _storageKey(userKey),
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
