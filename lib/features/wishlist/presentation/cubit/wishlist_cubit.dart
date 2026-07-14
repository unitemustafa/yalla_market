import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/wishlist_item.dart';
import '../../domain/usecases/wishlist_usecases.dart';

class WishlistCubit extends Cubit<List<WishlistItem>> {
  WishlistCubit(this._wishlistUseCases) : super(const []);

  final WishlistUseCases _wishlistUseCases;
  String? _currentUserKey;
  int _generation = 0;

  Future<void> loadWishlistForUser(String userKey) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      clearSession();
      return;
    }

    if (_currentUserKey != normalizedUserKey) {
      _generation++;
      _currentUserKey = normalizedUserKey;
      emit(const []);
    }
    final generation = _generation;
    final result = await _wishlistUseCases.getItems(normalizedUserKey);
    if (!_isCurrent(normalizedUserKey, generation)) return;
    result.when(success: emit, failure: (_) {});
  }

  Future<void> refresh() async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;
    await loadWishlistForUser(userKey);
  }

  Future<void> toggleItem(WishlistItem item) async {
    final userKey = _currentUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final generation = _generation;
    final result = await _wishlistUseCases.toggleItem(userKey, item);
    if (!_isCurrent(userKey, generation)) return;
    result.when(success: emit, failure: (_) {});
  }

  Future<void> toggleItemForUser(String userKey, WishlistItem item) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) return;

    if (_currentUserKey != normalizedUserKey) {
      _generation++;
      _currentUserKey = normalizedUserKey;
      emit(const []);
    }
    final generation = _generation;
    final result = await _wishlistUseCases.toggleItem(normalizedUserKey, item);
    if (!_isCurrent(normalizedUserKey, generation)) return;
    result.when(success: emit, failure: (_) {});
  }

  void clearSession() {
    _generation++;
    _currentUserKey = null;
    emit(const []);
  }

  bool _isCurrent(String userKey, int generation) =>
      generation == _generation && _currentUserKey == userKey && !isClosed;

  bool isFavorite(String productId) {
    return state.any((element) => element.productId == productId);
  }
}
