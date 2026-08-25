import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/usecases/get_home_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getHomeUseCase) : super(const HomeInitial());

  final GetHomeUseCase _getHomeUseCase;
  int _generation = 0;
  Future<void>? _loadInFlight;
  DateTime? _lastNetworkSuccessAt;

  DateTime? get lastNetworkSuccessAt => _lastNetworkSuccessAt;

  Future<void> loadHome({bool force = false}) async {
    final activeLoad = _loadInFlight;
    if (activeLoad != null) return activeLoad;
    if (!force && state is HomeReady) return;

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
      emit(HomeLoading(previousData: previousData));
    }

    final result = await _getHomeUseCase(forceRefresh: force);
    if (generation != _generation || isClosed) return;
    switch (result) {
      case ApiSuccess(:final data, :final origin):
        if (origin == DataOrigin.network) {
          _lastNetworkSuccessAt = DateTime.now().toUtc();
        }
        emit(HomeReady(data));
        if (!force && origin == DataOrigin.cache) {
          await _revalidate(generation);
        }
      case ApiFailure(:final failure):
        if (!silent || previousData == null) {
          emit(HomeFailure(failure.message, previousData: previousData));
        }
    }
  }

  Future<void> _revalidate(int generation) async {
    final refreshed = await _getHomeUseCase(forceRefresh: true);
    if (generation != _generation || isClosed) return;
    if (refreshed case ApiSuccess(:final data)) {
      _lastNetworkSuccessAt = DateTime.now().toUtc();
      emit(HomeReady(data));
    }
  }

  void clearSession() {
    _generation++;
    _loadInFlight = null;
    _lastNetworkSuccessAt = null;
    emit(const HomeInitial());
  }
}
