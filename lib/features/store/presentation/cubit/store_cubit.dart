import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/data_freshness.dart';
import '../../../../core/utils/coalesced_operation.dart';
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
    DateTime Function()? now,
  }) : _getMarket = getMarket,
       _getClassificationMarkets = getClassificationMarkets,
       _now = now ?? DateTime.now,
       _freshness = DataFreshness(now: now),
       super(const StoreInitial());

  final GetStoreUseCase _getStoreUseCase;
  final GetMarketUseCase? _getMarket;
  final GetClassificationMarketsUseCase? _getClassificationMarkets;
  int _generation = 0;
  Future<void>? _loadInFlight;
  final DateTime Function() _now;
  final DataFreshness _freshness;
  int? _activeRevision;
  final Map<String, DataFreshness> _marketFreshness = {};
  final Map<String, DataFreshness> _classificationFreshness = {};
  final Set<String> _loadedMarketIds = {};
  final Map<String, CoalescedOperation> _marketLoads = {};
  final Set<String> _loadedClassificationIds = {};
  final Map<String, CoalescedOperation> _classificationLoads = {};
  final Map<String, int> _marketRequestRevisions = {};
  final Map<String, int> _classificationRequestRevisions = {};

  DateTime? get lastNetworkSuccessAt {
    final times = [
      _freshness.lastNetworkSuccessAt,
      for (final item in _marketFreshness.values) item.lastNetworkSuccessAt,
      for (final item in _classificationFreshness.values)
        item.lastNetworkSuccessAt,
    ];
    if (times.any((time) => time == null)) return null;
    return times.cast<DateTime>().reduce((a, b) => a.isBefore(b) ? a : b);
  }

  void invalidate() {
    _freshness.invalidate();
    for (final freshness in _marketFreshness.values) {
      freshness.invalidate();
    }
    for (final freshness in _classificationFreshness.values) {
      freshness.invalidate();
    }
  }

  Future<void> refreshIfStale() async {
    if (_freshness.isStale) {
      await refreshSilently();
    } else {
      await _refreshLoadedDetails();
    }
  }

  Future<void> loadStore({bool force = false}) async {
    final activeLoad = _loadInFlight;
    if (activeLoad != null) return activeLoad;
    if (!force && state.data != null) return refreshIfStale();

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
    if (activeLoad != null) {
      final generation = _generation;
      final invalidatedWhileLoading = _activeRevision != _freshness.revision;
      await activeLoad;
      if (!isClosed &&
          generation == _generation &&
          invalidatedWhileLoading &&
          _freshness.isStale) {
        await refreshSilently();
      }
      return;
    }
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

    final generation = _generation;
    final revision = _freshness.revision;
    _activeRevision = revision;

    if (!silent || previousData == null) {
      emit(StoreLoading(previousData: previousData));
    }

    final result = await _getStoreUseCase(forceRefresh: force);
    if (generation != _generation || isClosed) return;
    switch (result) {
      case ApiSuccess(:final data, :final origin):
        if (origin == DataOrigin.network) {
          _freshness.markNetworkSuccess(revision: revision);
        }
        emit(StoreReady(_preserveLoadedDetails(data)));
        if (!force && origin == DataOrigin.cache) {
          final refreshed = await _getStoreUseCase(forceRefresh: true);
          if (generation != _generation || isClosed) return;
          if (refreshed case ApiSuccess(:final data, :final origin)) {
            if (origin == DataOrigin.network) {
              _freshness.markNetworkSuccess(revision: revision);
            }
            emit(StoreReady(_preserveLoadedDetails(data)));
          }
        }
        await _refreshLoadedDetails(force: force);
      case ApiFailure(:final failure):
        if (!silent || previousData == null) {
          emit(StoreFailure(failure.message, previousData: previousData));
        }
    }
  }

  StoreData _preserveLoadedDetails(StoreData summary) {
    final previous = state.data;
    if (previous == null) return summary;
    final knownClasses = {
      for (final category in summary.classifications) category.id,
      for (final category in summary.commonClassifications) category.id,
    };
    final updated = {
      for (final entry in summary.marketsByClassificationId.entries)
        entry.key: List<StoreMarketData>.of(entry.value),
    };
    for (final id in _loadedClassificationIds) {
      if (knownClasses.contains(id)) {
        updated[id] = List.of(previous.marketsFor(id));
      }
    }
    for (final entry in previous.marketsByClassificationId.entries) {
      if (!knownClasses.contains(entry.key)) continue;
      for (final market in entry.value) {
        if (!_loadedMarketIds.contains(market.id)) continue;
        final markets = updated.putIfAbsent(entry.key, () => []);
        final index = markets.indexWhere((item) => item.id == market.id);
        if (index < 0) {
          markets.add(market);
        } else {
          markets[index] = market;
        }
      }
    }
    return summary.copyWith(marketsByClassificationId: updated);
  }

  Future<void> _refreshLoadedDetails({bool force = false}) async {
    // A classification response contains previews, so restore full storefronts
    // afterwards even when their independent freshness window has not elapsed.
    for (final id in List.of(_classificationFreshness.keys)) {
      await ensureClassification(id, force: force);
    }
    await Future.wait([
      for (final id in List.of(_marketFreshness.keys))
        ensureMarket(id, force: force),
    ]);
  }

  Future<void> ensureMarket(String marketId, {bool force = false}) async {
    final id = marketId.trim();
    if (id.isEmpty || _getMarket == null) return;
    final loads = _marketLoads[id] ??= CoalescedOperation();
    final freshness = _marketFreshness[id] ??= DataFreshness(now: _now);
    final generation = _generation;
    final invalidatedWhileLoading =
        loads.isRunning && _marketRequestRevisions[id] != freshness.revision;
    await loads.run(() => _loadMarket(id, force: force));
    if (!isClosed &&
        generation == _generation &&
        invalidatedWhileLoading &&
        freshness.isStale) {
      await ensureMarket(id, force: true);
    }
  }

  Future<void> _loadMarket(String marketId, {bool force = false}) async {
    final normalized = marketId.trim();
    final getMarket = _getMarket;
    if (normalized.isEmpty ||
        getMarket == null ||
        (!force && _marketFreshness[normalized]?.isStale == false)) {
      return;
    }
    final generation = _generation;
    final freshness = _marketFreshness[normalized] ??= DataFreshness(now: _now);
    final revision = freshness.revision;
    _marketRequestRevisions[normalized] = revision;
    final result = await getMarket(normalized);
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
        final index = markets.indexWhere((item) => item.id == market.id);
        if (index < 0) {
          markets.add(market);
        } else {
          markets[index] = market;
        }
        _loadedMarketIds.add(normalized);
        if (result case ApiSuccess(origin: DataOrigin.network)) {
          freshness.markNetworkSuccess(revision: revision);
        }
        emit(
          StoreReady(current.copyWith(marketsByClassificationId: updatedMap)),
        );
      },
      failure: (_) {},
    );
  }

  Future<void> ensureClassification(
    String classificationId, {
    bool force = false,
  }) async {
    final id = classificationId.trim();
    if (id.isEmpty || _getClassificationMarkets == null) return;
    final loads = _classificationLoads[id] ??= CoalescedOperation();
    final freshness = _classificationFreshness[id] ??= DataFreshness(now: _now);
    final generation = _generation;
    final invalidatedWhileLoading =
        loads.isRunning &&
        _classificationRequestRevisions[id] != freshness.revision;
    await loads.run(() => _loadClassification(id, force: force));
    if (!isClosed &&
        generation == _generation &&
        invalidatedWhileLoading &&
        freshness.isStale) {
      await ensureClassification(id, force: true);
    }
  }

  Future<void> _loadClassification(
    String classificationId, {
    bool force = false,
  }) async {
    final normalized = classificationId.trim();
    final getClassificationMarkets = _getClassificationMarkets;
    if (normalized.isEmpty ||
        getClassificationMarkets == null ||
        (!force && _classificationFreshness[normalized]?.isStale == false)) {
      return;
    }
    final generation = _generation;
    final freshness = _classificationFreshness[normalized] ??= DataFreshness(
      now: _now,
    );
    final revision = freshness.revision;
    _classificationRequestRevisions[normalized] = revision;
    final result = await getClassificationMarkets(normalized);
    if (generation != _generation || isClosed) return;
    result.when(
      success: (markets) {
        final current = state.data;
        if (current == null) return;
        final updatedMap = {
          for (final entry in current.marketsByClassificationId.entries)
            entry.key: List<StoreMarketData>.of(entry.value),
          normalized: [
            for (final market in markets)
              // Preserve full details while replacing the category's membership.
              if (_loadedMarketIds.contains(market.id))
                current
                    .marketsFor(normalized)
                    .firstWhere(
                      (item) => item.id == market.id,
                      orElse: () => market,
                    )
              else
                market,
          ],
        };
        _loadedClassificationIds.add(normalized);
        if (result case ApiSuccess(origin: DataOrigin.network)) {
          freshness.markNetworkSuccess(revision: revision);
        }
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
    _marketLoads.clear();
    _loadedClassificationIds.clear();
    _classificationLoads.clear();
    _marketFreshness.clear();
    _classificationFreshness.clear();
    _marketRequestRevisions.clear();
    _classificationRequestRevisions.clear();
    _freshness.invalidate();
    emit(const StoreInitial());
  }
}
