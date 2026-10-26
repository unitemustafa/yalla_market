import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/coalesced_operation.dart';
import '../../../../core/utils/serial_operation.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/domain/favorite_page.dart';

import '../../../store/domain/entities/store_data.dart';
import '../../domain/usecases/market_wishlist_usecases.dart';

class MarketWishlistState {
  const MarketWishlistState({
    this.items = const [],
    this.favoriteIds,
    this.hasMore = false,
    this.loadingMore = false,
    this.moreError,
    this.loading = false,
    this.hasLoaded = false,
    this.busyIds = const {},
    this.errorMessage,
    this.errorRevision = 0,
  });

  final List<StoreMarketData> items;
  final Set<String>? favoriteIds;
  final bool hasMore;
  final bool loadingMore;
  final String? moreError;
  final bool loading;
  final bool hasLoaded;
  final Set<String> busyIds;
  final String? errorMessage;
  final int errorRevision;

  MarketWishlistState copyWith({
    List<StoreMarketData>? items,
    Set<String>? favoriteIds,
    bool? hasMore,
    bool? loadingMore,
    String? moreError,
    bool clearMoreError = false,
    bool? loading,
    bool? hasLoaded,
    Set<String>? busyIds,
    String? errorMessage,
    bool clearError = false,
    int? errorRevision,
  }) {
    return MarketWishlistState(
      items: items ?? this.items,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      moreError: clearMoreError ? null : moreError ?? this.moreError,
      loading: loading ?? this.loading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      busyIds: busyIds ?? this.busyIds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      errorRevision: errorRevision ?? this.errorRevision,
    );
  }
}

class MarketWishlistCubit extends Cubit<MarketWishlistState> {
  MarketWishlistCubit(this._useCases) : super(const MarketWishlistState());
  final MarketWishlistUseCases _useCases;
  final _loads = CoalescedOperation();
  final _operations = SerialOperation();
  final Map<String, bool> _overrides = {};
  String? _currentUserKey;
  int _generation = 0;
  int _page = 1;
  bool _dirtyPages = false;
  Future<void>? _more;
  Future<void> loadForUser(String userKey) {
    final key = userKey.trim();
    if (key.isEmpty) {
      clearSession();
      return Future.value();
    }
    if (_currentUserKey != key) {
      clearSession();
      _currentUserKey = key;
    }
    final generation = _generation;
    return _loads.run(() => _operations.run(() => _load(key, generation)));
  }

  Future<void> _load(String key, int generation) async {
    if (!_isCurrent(key, generation)) return;
    final previous = state;
    final pages = previous.hasLoaded ? _page : 1;
    emit(
      previous.copyWith(
        loading: true,
        loadingMore: false,
        clearError: true,
        clearMoreError: true,
      ),
    );
    final items = <String, StoreMarketData>{};
    Set<String>? ids;
    var loaded = 0;
    var hasMore = false;
    for (var number = 1; number <= pages; number++) {
      final result = await _useCases.page(page: number);
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
      final data = (result as ApiSuccess<FavoritePage<StoreMarketData>>).data;
      if (number == 1) ids = data.favoriteIds;
      for (final item in data.items) {
        items[item.id] = item.copyWithFavorite(true);
      }
      loaded = number;
      hasMore = data.hasMore;
      if (!hasMore) break;
    }
    _page = loaded;
    _dirtyPages = false;
    _overrides.clear();
    emit(
      MarketWishlistState(
        items: List.unmodifiable(items.values),
        favoriteIds: ids,
        hasLoaded: true,
        hasMore: hasMore,
        errorRevision: previous.errorRevision,
      ),
    );
  }

  Future<void> refresh() async {
    final key = _currentUserKey;
    if (key != null) await loadForUser(key);
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
    final previous = state;
    if (!previous.hasMore) return;
    emit(previous.copyWith(loadingMore: true, clearMoreError: true));
    final result = await _useCases.page(page: _page + 1);
    if (!_isCurrent(key, generation)) return;
    result.when(
      success: (data) {
        _page++;
        final merged = {
          for (final item in previous.items) item.id: item,
          for (final item in data.items) item.id: item.copyWithFavorite(true),
        };
        emit(
          previous.copyWith(
            items: List.unmodifiable(merged.values),
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

  Future<bool?> toggle(StoreMarketData market) {
    final key = _currentUserKey;
    if (key == null ||
        market.id.trim().isEmpty ||
        state.busyIds.contains(market.id)) {
      return Future.value(null);
    }
    final generation = _generation;
    return _operations.run(() => _toggle(key, generation, market));
  }

  Future<bool?> _toggle(
    String key,
    int generation,
    StoreMarketData market,
  ) async {
    if (!_isCurrent(key, generation)) return null;
    final previous = state;
    final wasFavorite = isFavorite(market);
    final next = !wasFavorite;
    final id = market.id;
    _overrides[id] = next;
    Set<String>? membership(bool favorite) {
      final ids = previous.favoriteIds;
      if (ids == null) return null;
      final updated = Set<String>.of(ids);
      if (favorite) {
        updated.add(id);
      } else {
        updated.remove(id);
      }
      return Set.unmodifiable(updated);
    }

    List<StoreMarketData> rows(bool favorite) => List.unmodifiable([
      ...previous.items.where((item) => item.id != id),
      if (favorite) market.copyWithFavorite(true),
    ]);
    emit(
      previous.copyWith(
        items: rows(next),
        favoriteIds: membership(next),
        busyIds: {...previous.busyIds, id},
        clearError: true,
      ),
    );
    final result = await _useCases.setFavorite(id, next);
    if (!_isCurrent(key, generation)) return null;
    return result.when(
      success: (favorite) {
        _overrides[id] = favorite;
        _dirtyPages = _useCases.supportsPaging;
        emit(
          state.copyWith(
            items: rows(favorite),
            favoriteIds: membership(favorite),
            busyIds: {...state.busyIds}..remove(id),
            clearError: true,
          ),
        );
        return favorite;
      },
      failure: (failure) {
        _overrides[id] = wasFavorite;
        emit(
          previous.copyWith(
            errorMessage: failure.message,
            errorRevision: previous.errorRevision + 1,
          ),
        );
        return null;
      },
    );
  }

  bool isFavorite(StoreMarketData market) =>
      _overrides[market.id] ??
      (state.favoriteIds?.contains(market.id) ??
          (state.hasLoaded
              ? state.items.any((item) => item.id == market.id)
              : market.isLiked));
  void clearSession() {
    _loads.reset();
    _operations.reset();
    _generation++;
    _currentUserKey = null;
    _page = 1;
    _dirtyPages = false;
    _more = null;
    _overrides.clear();
    emit(const MarketWishlistState());
  }

  bool _isCurrent(String key, int generation) =>
      !isClosed && generation == _generation && key == _currentUserKey;
}
