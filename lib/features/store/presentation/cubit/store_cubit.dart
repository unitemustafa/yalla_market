import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_store_usecase.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/entities/store_data.dart';
import 'store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  StoreCubit(this._getStoreUseCase, [this._repository])
    : super(const StoreInitial());

  final GetStoreUseCase _getStoreUseCase;
  final StoreRepository? _repository;
  int _generation = 0;
  final Set<String> _loadedMarketIds = {};
  final Set<String> _loadingMarketIds = {};
  final Set<String> _loadedClassificationIds = {};
  final Set<String> _loadingClassificationIds = {};

  Future<void> loadStore({bool force = false}) async {
    if (state is StoreLoading) return;
    if (!force && state is StoreReady) return;

    final generation = ++_generation;

    emit(StoreLoading(previousData: state.data));

    final result = await _getStoreUseCase(forceRefresh: force);
    if (generation != _generation || isClosed) return;
    result.when(
      success: (store) {
        _loadedMarketIds.clear();
        _loadingMarketIds.clear();
        _loadedClassificationIds.clear();
        _loadingClassificationIds.clear();
        emit(StoreReady(store));
      },
      failure: (failure) {
        emit(StoreFailure(failure.message, previousData: state.data));
      },
    );
  }

  Future<void> ensureMarket(String marketId) async {
    final normalized = marketId.trim();
    final repository = _repository;
    if (normalized.isEmpty ||
        repository == null ||
        _loadedMarketIds.contains(normalized) ||
        !_loadingMarketIds.add(normalized)) {
      return;
    }
    final generation = _generation;
    final result = await repository.getMarket(normalized);
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
    final repository = _repository;
    if (normalized.isEmpty ||
        repository == null ||
        _loadedClassificationIds.contains(normalized) ||
        !_loadingClassificationIds.add(normalized)) {
      return;
    }
    final generation = _generation;
    final result = await repository.getClassificationMarkets(normalized);
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
    _loadedMarketIds.clear();
    _loadingMarketIds.clear();
    _loadedClassificationIds.clear();
    _loadingClassificationIds.clear();
    emit(const StoreInitial());
  }
}
