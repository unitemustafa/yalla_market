import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_home_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getHomeUseCase) : super(const HomeInitial());

  final GetHomeUseCase _getHomeUseCase;

  Future<void> loadHome({bool force = false}) async {
    if (state is HomeLoading) return;
    if (!force && state is HomeReady) return;

    emit(HomeLoading(previousData: state.data));

    final result = await _getHomeUseCase();
    result.when(
      success: (home) => emit(HomeReady(home)),
      failure: (failure) {
        emit(HomeFailure(failure.message, previousData: state.data));
      },
    );
  }
}
