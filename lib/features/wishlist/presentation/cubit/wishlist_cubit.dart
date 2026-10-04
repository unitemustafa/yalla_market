import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/coalesced_operation.dart';

import '../../domain/entities/wishlist_item.dart';
import '../../domain/usecases/wishlist_usecases.dart';
import 'wishlist_state.dart';

class WishlistCubit extends Cubit<List<WishlistItem>> {
  WishlistCubit(this._wishlistUseCases) : super(WishlistState(const []));

  final WishlistUseCases _wishlistUseCases;
  String? _currentUserKey;
  final _loads = CoalescedOperation();
  int _generation = 0;

  Future<void> loadWishlistForUser(String userKey) {
    if (_currentUserKey != userKey.trim()) _loads.reset();
    return _loads.run(() => _loadWishlistForUser(userKey));
  }

  Future<void> _loadWishlistForUser(String userKey) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
      clearSession();
      return;
    }

    final userChanged = _currentUserKey != normalizedUserKey;
    if (userChanged) {
      _generation++;
      _currentUserKey = normalizedUserKey;
    }
    final previous = userChanged ? WishlistState(const []) : state;
    final hadLoaded = previous is WishlistState && previous.hasLoaded;
    final revision = previous is WishlistState ? previous.errorRevision : 0;
    final sameUserItems = hadLoaded ? previous : const <WishlistItem>[];
    emit(
      WishlistState(
        sameUserItems,
        loading: true,
        hasLoaded: hadLoaded,
        errorRevision: revision,
      ),
    );
    final generation = _generation;
    final result = await _wishlistUseCases.getItems(normalizedUserKey);
    if (!_isCurrent(normalizedUserKey, generation)) return;
    result.when(
      success: (items) =>
          emit(WishlistState(items, hasLoaded: true, errorRevision: revision)),
      failure: (failure) => emit(
        WishlistState(
          sameUserItems,
          hasLoaded: hadLoaded,
          errorMessage: failure.message,
          errorRevision: revision + 1,
        ),
      ),
    );
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
    result.when(
      success: (items) => emit(WishlistState(items, hasLoaded: true)),
      failure: (_) {},
    );
  }

  Future<void> toggleItemForUser(String userKey, WishlistItem item) async {
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) return;

    if (_currentUserKey != normalizedUserKey) {
      _loads.reset();
      _generation++;
      _currentUserKey = normalizedUserKey;
      emit(WishlistState(const []));
    }
    final generation = _generation;
    final result = await _wishlistUseCases.toggleItem(normalizedUserKey, item);
    if (!_isCurrent(normalizedUserKey, generation)) return;
    result.when(
      success: (items) => emit(WishlistState(items, hasLoaded: true)),
      failure: (_) {},
    );
  }

  void clearSession() {
    _loads.reset();
    _generation++;
    _currentUserKey = null;
    emit(WishlistState(const []));
  }

  bool _isCurrent(String userKey, int generation) =>
      generation == _generation && _currentUserKey == userKey && !isClosed;

  bool isFavorite(String productId) {
    return state.any((element) => element.productId == productId);
  }
}
