import '../../domain/entities/catalog_search_results.dart';

sealed class CatalogSearchState {
  const CatalogSearchState({
    this.query = '',
    this.results = const CatalogSearchResults(),
  });

  final String query;
  final CatalogSearchResults results;
}

final class CatalogSearchInitial extends CatalogSearchState {
  const CatalogSearchInitial();
}

final class CatalogSearchLoading extends CatalogSearchState {
  const CatalogSearchLoading({required super.query});
}

final class CatalogSearchNeedsCity extends CatalogSearchState {
  const CatalogSearchNeedsCity({required super.query});
}

final class CatalogSearchReady extends CatalogSearchState {
  const CatalogSearchReady({
    required super.query,
    required super.results,
    this.loadingMore = false,
    this.moreError,
  });

  final bool loadingMore;
  final String? moreError;
}

final class CatalogSearchFailure extends CatalogSearchState {
  const CatalogSearchFailure(this.message, {required super.query});

  final String message;
}
