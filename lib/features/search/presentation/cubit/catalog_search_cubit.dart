import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../../location/domain/usecases/location_usecases.dart';
import '../../domain/entities/catalog_search_results.dart';
import '../../domain/usecases/search_catalog_usecase.dart';

import 'catalog_search_state.dart';

class CatalogSearchCubit extends Cubit<CatalogSearchState> {
  CatalogSearchCubit(this._search, this._getSelectedCity)
    : super(const CatalogSearchInitial());

  void _emitReady(
    String query,
    CatalogSearchResults results, {
    bool loadingMore = false,
    String? moreError,
    CatalogSection? moreSection,
  }) => emit(
    CatalogSearchReady(
      query: query,
      results: results,
      visibleProducts: results.products,
      loadingMore: loadingMore,
      moreError: moreError,
      moreSection: moreSection,
    ),
  );

  final SearchCatalogUseCase _search;
  final GetSelectedCityUseCase _getSelectedCity;
  int _generation = 0;
  final Map<CatalogSection, int> _pages = {};
  String? _citySlug;

  Future<void> search(String query) async {
    final normalized = query.trim();
    final generation = ++_generation;

    _pages.clear();
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
      success: (results) => _emitReady(normalized, results),
      failure: (failure) =>
          emit(CatalogSearchFailure(failure.message, query: normalized)),
    );
  }

  Future<void> loadMore() => loadSection(CatalogSection.products);

  Future<void> loadSection(CatalogSection section) async {
    final previous = state;
    if (previous is! CatalogSearchReady ||
        previous.loadingMore ||
        _citySlug == null) {
      return;
    }
    final hasMore = switch (section) {
      CatalogSection.products => previous.results.hasMoreProducts,
      CatalogSection.markets => previous.results.hasMoreMarkets,
      CatalogSection.categories => previous.results.hasMoreCategories,
      CatalogSection.all => false,
    };
    if (!hasMore) {
      return;
    }
    final generation = _generation;
    final page = (_pages[section] ?? 1) + 1;
    emit(
      CatalogSearchReady(
        query: previous.query,
        results: previous.results,
        visibleProducts: previous.visibleProducts,
        loadingMore: true,
        moreSection: section,
      ),
    );
    final result = await _search.section(
      previous.query,
      citySlug: _citySlug!,
      section: section,
      page: page,
    );
    if (!_isCurrent(generation)) return;
    switch (result) {
      case ApiSuccess(:final data):
        _pages[section] = page;
        final old = previous.results;
        _emitReady(
          previous.query,
          CatalogSearchResults(
            products: section == CatalogSection.products
                ? _merge(old.products, data.products, (p) => p.id)
                : old.products,
            markets: section == CatalogSection.markets
                ? _merge(old.markets, data.markets, (m) => m.id)
                : old.markets,
            categories: section == CatalogSection.categories
                ? _merge(old.categories, data.categories, (c) => c.id)
                : old.categories,
            hasMoreProducts: section == CatalogSection.products
                ? data.hasMoreProducts
                : old.hasMoreProducts,
            hasMoreMarkets: section == CatalogSection.markets
                ? data.hasMoreMarkets
                : old.hasMoreMarkets,
            hasMoreCategories: section == CatalogSection.categories
                ? data.hasMoreCategories
                : old.hasMoreCategories,
          ),
        );
      case ApiFailure(:final failure):
        _emitReady(
          previous.query,
          previous.results,
          moreError: failure.message,
          moreSection: section,
        );
    }
  }

  List<T> _merge<T>(List<T> first, List<T> next, String Function(T) id) =>
      List.unmodifiable(
        {
          for (final item in first) id(item): item,
          for (final item in next) id(item): item,
        }.values,
      );

  bool _isCurrent(int generation) => !isClosed && generation == _generation;
}
