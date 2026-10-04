import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/data_freshness.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/usecases/get_home_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getHomeUseCase, {DateTime Function()? now})
    : _freshness = DataFreshness(now: now),
      super(const HomeInitial());

  final GetHomeUseCase _getHomeUseCase;
  int _generation = 0;
  Future<void>? _loadInFlight;
  final DataFreshness _freshness;
  int? _activeRevision;

  DateTime? get lastNetworkSuccessAt => _freshness.lastNetworkSuccessAt;

  void invalidate() => _freshness.invalidate();

  Future<void> refreshIfStale() async {
    if (_freshness.isStale) await refreshSilently();
  }

  Future<void> loadHome({bool force = false}) async {
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

    final generation = ++_generation;
    final revision = _freshness.revision;
    _activeRevision = revision;

    if (!silent || previousData == null) {
      emit(HomeLoading(previousData: previousData));
    }

    final result = await _getHomeUseCase(forceRefresh: force);
    if (generation != _generation || isClosed) return;
    switch (result) {
      case ApiSuccess(:final data, :final origin):
        if (origin == DataOrigin.network) {
          _freshness.markNetworkSuccess(revision: revision);
        }
        emit(HomeReady(data));
        if (!force && origin == DataOrigin.cache) {
          await _revalidate(generation, revision);
        }
      case ApiFailure(:final failure):
        if (!silent || previousData == null) {
          emit(HomeFailure(failure.message, previousData: previousData));
        }
    }
  }

  Future<void> _revalidate(int generation, int revision) async {
    final refreshed = await _getHomeUseCase(forceRefresh: true);
    if (generation != _generation || isClosed) return;
    if (refreshed case ApiSuccess(:final data, :final origin)) {
      if (origin == DataOrigin.network) {
        _freshness.markNetworkSuccess(revision: revision);
      }
      emit(HomeReady(data));
    }
  }

  void clearSession() {
    _generation++;
    _loadInFlight = null;
    _freshness.invalidate();
    emit(const HomeInitial());
  }
}
