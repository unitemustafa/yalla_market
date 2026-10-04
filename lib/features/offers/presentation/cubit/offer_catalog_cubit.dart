import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/data_freshness.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/coalesced_operation.dart';

import '../../domain/usecases/get_offers_usecase.dart';
import 'offer_catalog_state.dart';

class OfferCatalogCubit extends Cubit<OfferCatalogState> {
  OfferCatalogCubit(this._getOffers, {DateTime Function()? now})
    : _freshness = DataFreshness(now: now),
      super(const OfferCatalogState());

  final GetOffersUseCase _getOffers;
  final _loads = CoalescedOperation();
  int _generation = 0;
  final DataFreshness _freshness;
  int? _activeRevision;

  DateTime? get lastNetworkSuccessAt => _freshness.lastNetworkSuccessAt;

  void invalidate() => _freshness.invalidate();

  Future<void> refreshIfStale() async {
    if (!_freshness.isStale) return;
    final generation = _generation;
    final invalidatedWhileLoading =
        _loads.isRunning && _activeRevision != _freshness.revision;
    await loadOffers(force: true);
    if (!isClosed &&
        generation == _generation &&
        invalidatedWhileLoading &&
        _freshness.isStale) {
      await refreshIfStale();
    }
  }

  Future<void> loadOffers({bool force = false}) =>
      _loads.run(() => _loadOffers(force: force));

  Future<void> _loadOffers({bool force = false}) async {
    if (state.hasLoaded && !force && !_freshness.isStale) return;

    final generation = _generation;
    final revision = _freshness.revision;
    _activeRevision = revision;
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _getOffers();
    if (generation != _generation || isClosed) return;
    if (result case ApiSuccess(origin: DataOrigin.network)) {
      _freshness.markNetworkSuccess(revision: revision);
    }

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
    _loads.reset();
    _generation++;
    _freshness.invalidate();
    emit(const OfferCatalogState());
  }
}
