import '../../../../core/domain/favorite_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/coalesced_operation.dart';
import '../../../../core/utils/serial_operation.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/usecases/wishlist_usecases.dart';
import 'wishlist_state.dart';

class WishlistCubit extends Cubit<List<WishlistItem>> {
  WishlistCubit(this._wishlistUseCases) : super(WishlistState(const []));
  final WishlistUseCases _wishlistUseCases;
  final _loads = CoalescedOperation();
  final _operations = SerialOperation();
  String? _currentUserKey;
  int _generation = 0;
  int _page = 1;
  bool _dirtyPages = false;
  bool _newSession = true;
  Future<void>? _more;
  WishlistState get _current =>
      state is WishlistState ? state as WishlistState : WishlistState(state);

  void _activate(String key) {
    if (_currentUserKey == key) return;
    _reset(notify: false);
    _currentUserKey = key;
  }

  Future<void> loadWishlistForUser(String userKey) {
    final key = userKey.trim();
    if (key.isEmpty) {
      clearSession();
      return Future.value();
    }
    _activate(key);
    final generation = _generation;
    return _loads.run(() => _operations.run(() => _load(key, generation)));
  }

  Future<void> _load(String key, int generation) async {
    if (!_isCurrent(key, generation)) return;
    final previous = _newSession ? WishlistState(const []) : _current;
    _newSession = false;
    final pages = previous.hasLoaded ? _page : 1;
    emit(
      previous.copyWith(
        loading: true,
        loadingMore: false,
        clearError: true,
        clearMoreError: true,
      ),
    );
    final items = <String, WishlistItem>{};
    Set<String>? ids;
    var loaded = 0;
    var hasMore = false;
    for (var number = 1; number <= pages; number++) {
      final result = await _wishlistUseCases.getItems.page(key, page: number);
      if (!_isCurrent(key, generation)) return;
      if (result case ApiFailure(:final failure)) {
        emit(
          previous.copyWith(
            loading: false,
            loadingMore: false,
            errorMessage: failure.message,
            errorRevision: previous.errorRevision + 1,
          ),
        );
        return;
      }
      final data = (result as ApiSuccess<FavoritePage<WishlistItem>>).data;
      if (number == 1) ids = data.favoriteIds;
      for (final WishlistItem item in data.items) {
        items[item.productId] = item;
      }
      loaded = number;
      hasMore = data.hasMore;
      if (!hasMore) break;
    }
    _page = loaded;
    _dirtyPages = false;
    emit(
      WishlistState(
        items.values,
        hasLoaded: true,
        favoriteIds: ids,
        hasMore: hasMore,
        errorRevision: previous.errorRevision,
      ),
    );
  }

  Future<void> refresh() async {
    final key = _currentUserKey;
    if (key != null) await loadWishlistForUser(key);
  }

  Future<void> loadMore() {
    final existing = _more;
    if (existing != null) return existing;
    final key = _currentUserKey;
    if (key == null) return Future.value();
    final generation = _generation;
    final operation = _operations.run(() => _loadMore(key, generation));
    _more = operation;
    return operation.whenComplete(() {
      if (identical(_more, operation)) _more = null;
    });
  }

  Future<void> _loadMore(String key, int generation) async {
    if (!_isCurrent(key, generation)) return;
    if (_dirtyPages) {
      await _load(key, generation);
      if (_dirtyPages || !_isCurrent(key, generation)) return;
    }
    final previous = _current;
    if (!previous.hasMore) return;
    emit(previous.copyWith(loadingMore: true, clearMoreError: true));
    final result = await _wishlistUseCases.getItems.page(key, page: _page + 1);
    if (!_isCurrent(key, generation)) return;
    result.when(
      success: (data) {
        _page++;
        final merged = {
          for (final item in previous) item.productId: item,
          for (final item in data.items) item.productId: item,
        };
        emit(
          previous.copyWith(
            items: merged.values,
            hasMore: data.hasMore,
            loadingMore: false,
            clearMoreError: true,
          ),
        );
      },
      failure: (failure) => emit(
        previous.copyWith(loadingMore: false, moreError: failure.message),
      ),
    );
  }

  Future<void> toggleItem(WishlistItem item) {
    final key = _currentUserKey;
    if (key == null) return Future.value();
    final generation = _generation;
    return _operations.run(() => _toggle(key, generation, item));
  }

  Future<void> _toggle(String key, int generation, WishlistItem item) async {
    if (!_isCurrent(key, generation)) return;
    if (_newSession) {
      _newSession = false;
      emit(WishlistState(const []));
    }
    final result = await _wishlistUseCases.toggleItem(key, item);
    if (!_isCurrent(key, generation)) return;
    result.when(
      success: (items) {
        final previous = _current;
        final ids = Set<String>.of(
          previous.favoriteIds ?? previous.map((i) => i.productId),
        );
        if (items.any((i) => i.productId == item.productId)) {
          ids.add(item.productId);
        } else {
          ids.remove(item.productId);
        }
        _dirtyPages = _wishlistUseCases.getItems.supportsPaging;
        emit(
          previous.copyWith(
            items: items,
            hasLoaded: true,
            favoriteIds: Set.unmodifiable(ids),
            clearError: true,
          ),
        );
      },
      failure: (_) {},
    );
  }

  Future<void> toggleItemForUser(String userKey, WishlistItem item) async {
    final key = userKey.trim();
    if (key.isEmpty) return;
    _activate(key);
    final generation = _generation;
    if (_wishlistUseCases.getItems.supportsPaging && !_current.hasLoaded) {
      await loadWishlistForUser(key);
      if (!_isCurrent(key, generation) || !_current.hasLoaded) return;
    }
    await toggleItem(item);
  }

  void clearSession() => _reset();
  void _reset({bool notify = true}) {
    _loads.reset();
    _operations.reset();
    _generation++;
    _currentUserKey = null;
    _page = 1;
    _dirtyPages = false;
    _more = null;
    _newSession = true;
    if (notify) emit(WishlistState(const []));
  }

  bool _isCurrent(String key, int generation) =>
      !isClosed && generation == _generation && key == _currentUserKey;
  bool isFavorite(String id) => _current.containsProduct(id);
}
