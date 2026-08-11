import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_offers_usecase.dart';
import 'offer_catalog_state.dart';

class OfferCatalogCubit extends Cubit<OfferCatalogState> {
  OfferCatalogCubit(this._getOffers) : super(const OfferCatalogState());

  final GetOffersUseCase _getOffers;
  int _generation = 0;

  Future<void> loadOffers({bool force = false}) async {
    if (state.isLoading) return;
    if (state.hasLoaded && !force) return;

    final generation = _generation;
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _getOffers();
    if (generation != _generation || isClosed) return;

    result.when(
      success: (offers) => emit(
        OfferCatalogState(offers: List.unmodifiable(offers), hasLoaded: true),
      ),
      failure: (failure) => emit(
        state.copyWith(
          isLoading: false,
          hasLoaded: state.hasLoaded || state.offers.isNotEmpty,
          errorMessage: failure.message,
        ),
      ),
    );
  }

  void clearSession() {
    _generation++;
    emit(const OfferCatalogState());
  }
}
