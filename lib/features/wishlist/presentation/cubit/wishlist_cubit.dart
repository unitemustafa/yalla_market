import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/wishlist_item.dart';
import '../../domain/usecases/wishlist_usecases.dart';

class WishlistCubit extends Cubit<List<WishlistItem>> {
  WishlistCubit(this._wishlistUseCases) : super(const []);

  final WishlistUseCases _wishlistUseCases;
  String? _currentUserKey;

  Future<void> loadWishlistForUser(String userKey) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      clearSession();
      return;
    }

    _currentUserKey = normalizedUserKey;
    final result = await _wishlistUseCases.getItems(normalizedUserKey);
    result.when(success: emit, failure: (_) {});
  }

  Future<void> toggleItem(WishlistItem item) async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final result = await _wishlistUseCases.toggleItem(userKey, item);
    result.when(success: emit, failure: (_) {});
  }

  Future<void> toggleItemForUser(String userKey, WishlistItem item) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) return;

    _currentUserKey = normalizedUserKey;
    final result = await _wishlistUseCases.toggleItem(normalizedUserKey, item);
    result.when(success: emit, failure: (_) {});
  }

  void clearSession() {
    _currentUserKey = null;
    emit(const []);
  }

  bool isFavorite(String productId) {
    return state.any((element) => element.productId == productId);
  }
}
