import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_store_usecase.dart';
import 'store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  StoreCubit(this._getStoreUseCase) : super(const StoreInitial());

  final GetStoreUseCase _getStoreUseCase;

  Future<void> loadStore({bool force = false}) async {
    if (state is StoreLoading) return;
    if (!force && state is StoreReady) return;

    emit(StoreLoading(previousData: state.data));

    final result = await _getStoreUseCase();
    result.when(
      success: (store) => emit(StoreReady(store)),
      failure: (failure) {
        emit(StoreFailure(failure.message, previousData: state.data));
      },
    );
  }
}
