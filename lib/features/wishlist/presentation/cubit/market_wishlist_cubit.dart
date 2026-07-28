import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../store/domain/entities/store_data.dart';
import '../../domain/repositories/market_wishlist_repository.dart';

class MarketWishlistState {
  const MarketWishlistState({
    this.items = const [],
    this.loading = false,
    this.busyIds = const {},
    this.errorMessage,
    this.errorRevision = 0,
  });

  final List<StoreMarketData> items;
  final bool loading;
  final Set<String> busyIds;
  final String? errorMessage;
  final int errorRevision;

  MarketWishlistState copyWith({
    List<StoreMarketData>? items,
    bool? loading,
    Set<String>? busyIds,
    String? errorMessage,
    bool clearError = false,
    int? errorRevision,
  }) {
    return MarketWishlistState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      busyIds: busyIds ?? this.busyIds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      errorRevision: errorRevision ?? this.errorRevision,
    );
  }
}

class MarketWishlistCubit extends Cubit<MarketWishlistState> {
  MarketWishlistCubit(this._repository) : super(const MarketWishlistState());

  final MarketWishlistRepository _repository;
  final Map<String, bool> _overrides = {};
  String? _currentUserKey;
  int _generation = 0;
  bool _loaded = false;

  Future<void> loadForUser(String userKey) async {
    final normalized = userKey.trim();
    if (normalized.isEmpty) {
      clearSession();
      return;
    }
    if (_currentUserKey != normalized) {
      _generation++;
      _currentUserKey = normalized;
      _loaded = false;
      _overrides.clear();
      emit(const MarketWishlistState(loading: true));
    } else {
      emit(state.copyWith(loading: true, clearError: true));
    }

    final generation = _generation;
    final result = await _repository.getItems();
    if (!_isCurrent(normalized, generation)) return;
    result.when(
      success: (items) {
        _loaded = true;
        _overrides.clear();
        emit(
          MarketWishlistState(
            items: List.unmodifiable(
              items.map((item) => item.copyWithFavorite(true)),
            ),
          ),
        );
      },
      failure: (failure) {
        emit(
          state.copyWith(
            loading: false,
            errorMessage: failure.message,
            errorRevision: state.errorRevision + 1,
          ),
        );
      },
    );
  }

  Future<void> refresh() async {
    final userKey = _currentUserKey;
    if (userKey == null) return;
    await loadForUser(userKey);
  }

  Future<void> toggle(StoreMarketData market) async {
    final userKey = _currentUserKey;
    final id = market.id.trim();
    if (userKey == null || id.isEmpty || state.busyIds.contains(id)) return;

    final previousItems = state.items;
    final wasFavorite = isFavorite(market);
    final nextFavorite = !wasFavorite;
    _overrides[id] = nextFavorite;
    final nextItems = nextFavorite
        ? [
            ...state.items.where((item) => item.id != id),
            market.copyWithFavorite(true),
          ]
        : state.items.where((item) => item.id != id).toList(growable: false);
    emit(
      state.copyWith(
        items: List.unmodifiable(nextItems),
        busyIds: {...state.busyIds, id},
        clearError: true,
      ),
    );

    final generation = _generation;
    final result = await _repository.setFavorite(id, nextFavorite);
    if (!_isCurrent(userKey, generation)) return;
    result.when(
      success: (favorite) {
        _overrides[id] = favorite;
        final items = favorite
            ? [
                ...state.items.where((item) => item.id != id),
                market.copyWithFavorite(true),
              ]
            : state.items
                  .where((item) => item.id != id)
                  .toList(growable: false);
        emit(
          state.copyWith(
            items: List.unmodifiable(items),
            busyIds: {...state.busyIds}..remove(id),
            clearError: true,
          ),
        );
      },
      failure: (failure) {
        _overrides[id] = wasFavorite;
        emit(
          state.copyWith(
            items: previousItems,
            busyIds: {...state.busyIds}..remove(id),
            errorMessage: failure.message,
            errorRevision: state.errorRevision + 1,
          ),
        );
      },
    );
  }

  bool isFavorite(StoreMarketData market) {
    final override = _overrides[market.id];
    if (override != null) return override;
    if (_loaded) return state.items.any((item) => item.id == market.id);
    return market.isLiked;
  }

  void clearSession() {
    _generation++;
    _currentUserKey = null;
    _loaded = false;
    _overrides.clear();
    emit(const MarketWishlistState());
  }

  bool _isCurrent(String userKey, int generation) =>
      !isClosed && generation == _generation && _currentUserKey == userKey;
}
