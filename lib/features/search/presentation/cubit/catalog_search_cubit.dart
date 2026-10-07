import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../../location/domain/usecases/location_usecases.dart';
import '../../domain/entities/catalog_search_results.dart';
import '../../domain/usecases/search_catalog_usecase.dart';
import 'catalog_search_state.dart';

class CatalogSearchCubit extends Cubit<CatalogSearchState> {
  CatalogSearchCubit(this._search, this._getSelectedCity)
    : super(const CatalogSearchInitial());

  final SearchCatalogUseCase _search;
  final GetSelectedCityUseCase _getSelectedCity;
  int _generation = 0;
  int _page = 1;
  String? _citySlug;

  Future<void> search(String query) async {
    final normalized = query.trim();
    final generation = ++_generation;
    _page = 1;
    if (normalized.isEmpty) {
      emit(const CatalogSearchInitial());
      return;
    }
    emit(CatalogSearchLoading(query: normalized));
    final cityResult = await _getSelectedCity();
    if (!_isCurrent(generation)) return;
    switch (cityResult) {
      case ApiFailure(:final failure):
        emit(CatalogSearchFailure(failure.message, query: normalized));
        return;
      case ApiSuccess(data: final city):
        if (city == null) {
          emit(CatalogSearchNeedsCity(query: normalized));
          return;
        }
        _citySlug = city.slug;
    }
    final result = await _search(normalized, citySlug: _citySlug!);
    if (!_isCurrent(generation)) return;
    result.when(
      success: (results) =>
          emit(CatalogSearchReady(query: normalized, results: results)),
      failure: (failure) =>
          emit(CatalogSearchFailure(failure.message, query: normalized)),
    );
  }

  Future<void> loadMore() async {
    final previous = state;
    if (previous is! CatalogSearchReady ||
        previous.loadingMore ||
        !previous.results.hasMoreProducts ||
        _citySlug == null) {
      return;
    }
    final generation = _generation;
    emit(
      CatalogSearchReady(
        query: previous.query,
        results: previous.results,
        loadingMore: true,
      ),
    );
    final result = await _search(
      previous.query,
      citySlug: _citySlug!,
      page: _page + 1,
    );
    if (!_isCurrent(generation)) return;
    result.when(
      success: (next) {
        _page++;
        final seen = <String>{};
        emit(
          CatalogSearchReady(
            query: previous.query,
            results: CatalogSearchResults(
              products: [...previous.results.products, ...next.products]
                  .where((product) => seen.add(product.id))
                  .toList(growable: false),
              markets: previous.results.markets,
              categories: previous.results.categories,
              hasMoreProducts: next.hasMoreProducts,
            ),
          ),
        );
      },
      failure: (failure) => emit(
        CatalogSearchReady(
          query: previous.query,
          results: previous.results,
          moreError: failure.message,
        ),
      ),
    );
  }

  bool _isCurrent(int generation) => !isClosed && generation == _generation;
}
