import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/store_data.dart';
import '../../domain/usecases/get_classification_markets_usecase.dart';
import '../../domain/usecases/get_market_usecase.dart';
import '../../domain/usecases/get_store_usecase.dart';
import 'store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  StoreCubit(
    this._getStoreUseCase, {
    GetMarketUseCase? getMarket,
    GetClassificationMarketsUseCase? getClassificationMarkets,
  }) : _getMarket = getMarket,
       _getClassificationMarkets = getClassificationMarkets,
       super(const StoreInitial());

  final GetStoreUseCase _getStoreUseCase;
  final GetMarketUseCase? _getMarket;
  final GetClassificationMarketsUseCase? _getClassificationMarkets;
  int _generation = 0;
  Future<void>? _loadInFlight;
  final Set<String> _loadedMarketIds = {};
  final Set<String> _loadingMarketIds = {};
  final Set<String> _loadedClassificationIds = {};
  final Set<String> _loadingClassificationIds = {};

  Future<void> loadStore({bool force = false}) async {
    final activeLoad = _loadInFlight;
    if (activeLoad != null) return activeLoad;
    if (!force && state is StoreReady) return;

    final operation = _load(force: force, silent: false);
    _loadInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_loadInFlight, operation)) _loadInFlight = null;
    }
  }

  Future<void> refreshSilently() async {
    final activeLoad = _loadInFlight;
    if (activeLoad != null) return activeLoad;
    final operation = _load(force: true, silent: true);
    _loadInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_loadInFlight, operation)) _loadInFlight = null;
    }
  }

  Future<void> _load({required bool force, required bool silent}) async {
    final previousData = state.data;

    final generation = ++_generation;

    if (!silent || previousData == null) {
      emit(StoreLoading(previousData: previousData));
    }

    final result = await _getStoreUseCase(forceRefresh: force);
    if (generation != _generation || isClosed) return;
    switch (result) {
      case ApiSuccess(:final data, :final origin):
        _loadedMarketIds.clear();
        _loadingMarketIds.clear();
        _loadedClassificationIds.clear();
        _loadingClassificationIds.clear();
        emit(StoreReady(data));
        if (!force && origin == DataOrigin.cache) {
          final refreshed = await _getStoreUseCase(forceRefresh: true);
          if (generation != _generation || isClosed) return;
          if (refreshed case ApiSuccess(:final data)) emit(StoreReady(data));
        }
      case ApiFailure(:final failure):
        if (!silent || previousData == null) {
          emit(StoreFailure(failure.message, previousData: previousData));
        }
    }
  }

  Future<void> ensureMarket(String marketId) async {
    final normalized = marketId.trim();
    final getMarket = _getMarket;
    if (normalized.isEmpty ||
        getMarket == null ||
        _loadedMarketIds.contains(normalized) ||
        !_loadingMarketIds.add(normalized)) {
      return;
    }
    final generation = _generation;
    final result = await getMarket(normalized);
    _loadingMarketIds.remove(normalized);
    if (generation != _generation || isClosed) return;
    result.when(
      success: (market) {
        final current = state.data;
        if (current == null) return;
        final updatedMap = {
          for (final entry in current.marketsByClassificationId.entries)
            entry.key: List<StoreMarketData>.of(entry.value),
        };
        final markets = updatedMap.putIfAbsent(
          market.classificationId,
          () => <StoreMarketData>[],
        );
        markets.removeWhere((item) => item.id == market.id);
        markets.add(market);
        _loadedMarketIds.add(normalized);
        emit(
          StoreReady(current.copyWith(marketsByClassificationId: updatedMap)),
        );
      },
      failure: (_) {},
    );
  }

  Future<void> ensureClassification(String classificationId) async {
    final normalized = classificationId.trim();
    final getClassificationMarkets = _getClassificationMarkets;
    if (normalized.isEmpty ||
        getClassificationMarkets == null ||
        _loadedClassificationIds.contains(normalized) ||
        !_loadingClassificationIds.add(normalized)) {
      return;
    }
    final generation = _generation;
    final result = await getClassificationMarkets(normalized);
    _loadingClassificationIds.remove(normalized);
    if (generation != _generation || isClosed) return;
    result.when(
      success: (markets) {
        final current = state.data;
        if (current == null) return;
        final updatedMap = {
          for (final entry in current.marketsByClassificationId.entries)
            entry.key: List<StoreMarketData>.of(entry.value),
          normalized: List<StoreMarketData>.unmodifiable(markets),
        };
        _loadedClassificationIds.add(normalized);
        emit(
          StoreReady(current.copyWith(marketsByClassificationId: updatedMap)),
        );
      },
      failure: (_) {},
    );
  }

  void clearSession() {
    _generation++;
    _loadInFlight = null;
    _loadedMarketIds.clear();
    _loadingMarketIds.clear();
    _loadedClassificationIds.clear();
    _loadingClassificationIds.clear();
    emit(const StoreInitial());
  }
}
