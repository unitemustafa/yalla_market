import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_home_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getHomeUseCase) : super(const HomeInitial());

  final GetHomeUseCase _getHomeUseCase;
  int _generation = 0;

  Future<void> loadHome({bool force = false}) async {
    if (state is HomeLoading) return;
    if (!force && state is HomeReady) return;

    final generation = ++_generation;

    emit(HomeLoading(previousData: state.data));

    final result = await _getHomeUseCase();
    if (generation != _generation || isClosed) return;
    result.when(
      success: (home) => emit(HomeReady(home)),
      failure: (failure) {
        emit(HomeFailure(failure.message, previousData: state.data));
      },
    );
  }

  void clearSession() {
    _generation++;
    emit(const HomeInitial());
  }
}
