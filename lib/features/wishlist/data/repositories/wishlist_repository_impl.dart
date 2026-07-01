import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  @override
  Future<ApiResult<List<WishlistItem>>> getItems(String userKey) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      return const ApiResult.success([]);
    }

    final preferences = await SharedPreferences.getInstance();
    final items = await _readItems(preferences, normalizedUserKey);
    return ApiResult.success(List.unmodifiable(items));
  }

  @override
  Future<ApiResult<List<WishlistItem>>> toggleItem(
    String userKey,
    WishlistItem item,
  ) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      return const ApiResult.failure(
        ValidationFailure('User is required for wishlist.'),
      );
    }

    final productId = item.productId.trim();
    if (productId.isEmpty) {
      final preferences = await SharedPreferences.getInstance();
      final items = await _readItems(preferences, normalizedUserKey);
      return ApiResult.success(List.unmodifiable(items));
    }

    final preferences = await SharedPreferences.getInstance();
    final items = await _readItems(preferences, normalizedUserKey);
    final exists = items.any((element) => element.productId == productId);
    if (exists) {
      items.removeWhere((element) => element.productId == productId);
    } else {
      items.add(item);
    }

    await preferences.setString(
      _storageKey(normalizedUserKey),
      jsonEncode(items.map((element) => element.toJson()).toList()),
    );

    return ApiResult.success(List.unmodifiable(items));
  }

  String _storageKey(String userKey) => 'wishlist_user_$userKey';

  Future<List<WishlistItem>> _readItems(
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
          .map(WishlistItem.fromJson)
          .where((item) => item.productId.trim().isNotEmpty)
          .toList();
    } catch (_) {
      await preferences.remove(key);
      return [];
    }
  }
}
