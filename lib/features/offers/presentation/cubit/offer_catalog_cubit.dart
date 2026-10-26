import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/data_freshness.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/coalesced_operation.dart';

import '../../domain/usecases/get_offers_usecase.dart';
import '../../domain/usecases/get_offer_details_usecase.dart';
import '../../domain/entities/offer_data.dart';
import '../../../../core/errors/failure.dart';
import 'offer_catalog_state.dart';

class OfferCatalogCubit extends Cubit<OfferCatalogState> {
  OfferCatalogCubit(
    this._getOffers, {
    DateTime Function()? now,
    GetOfferDetailsUseCase? getDetails,
  }) : _getDetails = getDetails,
       _freshness = DataFreshness(now: now),
       super(const OfferCatalogState());

  final GetOffersUseCase _getOffers;
  final GetOfferDetailsUseCase? _getDetails;
  final Map<String, Future<ApiResult<OfferData>>> _details = {};
  Future<ApiResult<OfferData>> loadDetails(String id) async {
    final existing = _details[id];
    if (existing != null) return existing;
    final useCase = _getDetails;
    if (useCase == null) {
      final offer = state.offers
          .where((o) => o.id == id && !o.isSummary)
          .firstOrNull;
      return offer == null
          ? const ApiResult.failure(
              ServerFailure('Offer is no longer available.'),
            )
          : ApiResult.success(offer);
    }
    final generation = _generation;
    final operation = useCase(id).then<ApiResult<OfferData>>((result) {
      if (generation != _generation || isClosed) {
        return const ApiResult.failure(
          ServerFailure('Offer is no longer available.'),
        );
      }
      return result;
    });
    _details[id] = operation;
    try {
      return await operation;
    } finally {
      if (identical(_details[id], operation)) _details.remove(id);
    }
  }

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
    _details.clear();
    _generation++;
    _freshness.invalidate();
    emit(const OfferCatalogState());
  }
}
