import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository, CartMemoryCache {
  static final _pending = <String, Future<void>>{};
  // Decode once per persisted snapshot. Raw-value comparison also observes
  // writes by another repository instance without sharing mutable cart lists.
  String? _cachedRaw;
  String? _cachedKey;
  List<CartItemData> _cachedItems = const [];
  String? _memoryUserKey;
  int _memoryRevision = 0;
  void _dropSnapshot() {
    _memoryRevision++;
    _cachedRaw = null;
    _cachedKey = null;
    _cachedItems = const [];
  }

  @override
  void releaseMemory(String userKey) {
    if (_memoryUserKey == userKey.trim()) {
      _memoryUserKey = null;
      _dropSnapshot();
    }
  }

  Future<ApiResult<List<CartItemData>>> _serialized(
    String userKey,
    Future<ApiResult<List<CartItemData>>> Function() action,
  ) async {
    final key = userKey.trim();
    final previous = _pending[key] ?? Future<void>.value();
    final finished = Completer<void>();
    _pending[key] = finished.future;
    try {
      await previous;
      return await action();
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not save the cart. Please try again.'),
      );
    } finally {
      finished.complete();
      if (identical(_pending[key], finished.future)) _pending.remove(key);
    }
  }

  @override
  Future<ApiResult<List<CartItemData>>> getItems(String userKey) {
    final key = userKey.trim();
    if (_memoryUserKey != key) {
      _dropSnapshot();
      _memoryUserKey = key;
    }
    return _serialized(userKey, () => _getItems(userKey));
  }

  @override
  Future<ApiResult<List<CartItemData>>> addItem(
    String userKey,
    CartItemData item,
    int quantityToAdd,
  ) => _serialized(userKey, () => _addItem(userKey, item, quantityToAdd));

  @override
  Future<ApiResult<List<CartItemData>>> incrementQuantity(
    String userKey,
    String id,
  ) => _serialized(userKey, () => _incrementQuantity(userKey, id));

  @override
  Future<ApiResult<List<CartItemData>>> decrementQuantity(
    String userKey,
    String id,
  ) => _serialized(userKey, () => _decrementQuantity(userKey, id));

  @override
  Future<ApiResult<List<CartItemData>>> removeItem(String userKey, String id) =>
      _serialized(userKey, () => _removeItem(userKey, id));

  @override
  Future<ApiResult<List<CartItemData>>> clear(String userKey) =>
      _serialized(userKey, () => _clear(userKey));

  Future<ApiResult<List<CartItemData>>> _getItems(String userKey) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      return const ApiResult.success([]);
    }

    final preferences = await SharedPreferences.getInstance();
    final items = await _readItems(preferences, normalizedUserKey);
    return ApiResult.success(List.unmodifiable(items));
  }

  Future<ApiResult<List<CartItemData>>> _addItem(
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
    final normalizedItem = item.isOffer
        ? item.copyWith(itemType: 'offer', quantity: 1)
        : item;
    final normalizedQuantity = item.isOffer ? 1 : quantityToAdd;
    final index = items.indexWhere(
      (existing) => existing.id == normalizedItem.id,
    );
    if (index >= 0) {
      items[index] = normalizedItem.isOffer
          ? normalizedItem
          : items[index].copyWith(
              quantity: items[index].quantity + normalizedQuantity,
            );
    } else {
      items.add(normalizedItem.copyWith(quantity: normalizedQuantity));
    }

    await _saveItems(preferences, normalizedUserKey, items);
    return ApiResult.success(List.unmodifiable(items));
  }

  Future<ApiResult<List<CartItemData>>> _incrementQuantity(
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

  Future<ApiResult<List<CartItemData>>> _decrementQuantity(
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

  Future<ApiResult<List<CartItemData>>> _removeItem(
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

  Future<ApiResult<List<CartItemData>>> _clear(String userKey) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      return const ApiResult.failure(
        ValidationFailure('User is required for cart.'),
      );
    }

    final preferences = await SharedPreferences.getInstance();
    if (_memoryUserKey == normalizedUserKey) _dropSnapshot();
    final removed = await preferences.remove(_storageKey(normalizedUserKey));
    if (!removed) throw StateError('Cart storage clear failed.');
    return const ApiResult.success([]);
  }

  String _storageKey(String userKey) => 'cart_user_$userKey';

  Future<List<CartItemData>> _readItems(
    SharedPreferences preferences,
    String userKey,
  ) async {
    final key = _storageKey(userKey);
    final raw = preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      if (_cachedKey == key) _dropSnapshot();
      return [];
    }
    if (_cachedKey == key && _cachedRaw == raw) {
      return List.of(_cachedItems);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final items = decoded
          .whereType<Map<String, dynamic>>()
          .map(CartItemData.fromJson)
          .where((item) => item.id.trim().isNotEmpty)
          .toList();
      if (_memoryUserKey == userKey.trim()) {
        _cachedKey = key;
        _cachedRaw = raw;
        _cachedItems = List.unmodifiable(items);
      }
      return items;
    } catch (_) {
      await preferences.remove(key);
      return [];
    }
  }

  Future<void> _saveItems(
    SharedPreferences preferences,
    String userKey,
    List<CartItemData> items,
  ) async {
    final revision = _memoryRevision;
    final raw = jsonEncode(items.map((item) => item.toJson()).toList());
    final saved = await preferences.setString(_storageKey(userKey), raw);
    if (!saved) throw StateError('Cart storage write failed.');
    if (_memoryUserKey == userKey.trim() && revision == _memoryRevision) {
      _cachedKey = _storageKey(userKey);
      _cachedRaw = raw;
      _cachedItems = List.unmodifiable(items);
    }
  }
}
