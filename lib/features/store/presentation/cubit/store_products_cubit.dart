import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/cache/data_freshness.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/product_data.dart';
import '../../domain/entities/store_product_page.dart';
import '../../domain/usecases/get_store_products_usecase.dart';

class StoreProductsState {
  const StoreProductsState({
    this.products = const [],
    this.visibleProducts = const [],
    this.isLoading = false,
    this.loadingMore = false,
    this.error,
    this.moreError,
    this.hasMore = false,
    this.count = 0,

    this.selectionKey,
  });
  final List<ProductData> products;
  final List<ProductData> visibleProducts;
  final bool isLoading;
  final bool loadingMore;
  final String? error;
  final String? moreError;
  final bool hasMore;
  final int count;

  final Object? selectionKey;
}

class StoreProductsCubit extends Cubit<StoreProductsState> {
  StoreProductsCubit(this._getProducts, {DateTime Function()? now})
    : _freshness = DataFreshness(now: now),
      super(const StoreProductsState());
  final GetStoreProductsUseCase _getProducts;
  final DataFreshness _freshness;
  String _marketId = '';
  String _query = '';
  String? _subcategoryId;
  StoreProductSort _sort = StoreProductSort.name;
  String _scopeKey = '';
  bool _configured = false;
  int _generation = 0;
  int _page = 0;

  Object? _displayedSelectionKey;
  int _refreshTarget = 1;
  bool _pendingInvalidation = false;

  Future<void> configure({
    required String marketId,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
    String scopeKey = '',
  }) async {
    if (isClosed) return;
    final category = subcategoryId?.trim();
    final scopeChanged =
        !_configured || _marketId != marketId.trim() || _scopeKey != scopeKey;
    final changed =
        !_configured ||
        _marketId != marketId.trim() ||
        _query != query.trim() ||
        _subcategoryId != category ||
        _sort != sort ||
        _scopeKey != scopeKey;
    if (!changed) return;
    _freshness.invalidate();
    _pendingInvalidation = false;
    _configured = true;
    _marketId = marketId.trim();
    _query = query.trim();
    _subcategoryId = category;
    _sort = sort;
    _scopeKey = scopeKey;
    await refresh(clear: scopeChanged);
  }

  Future<void> refresh({bool clear = false, bool preservePages = false}) async {
    if (isClosed || !_configured) return;
    final generation = ++_generation;
    _refreshTarget = preservePages && _page > 0 ? _page : 1;
    if (clear) _page = 0;
    if (clear) _displayedSelectionKey = null;
    _emitVisible(
      clear ? const [] : state.products,
      isLoading: true,
      hasMore: clear ? false : state.hasMore,
      count: clear ? 0 : state.count,
    );
    await _fetchSnapshot(generation, _refreshTarget);
  }

  Future<void> retry() => state.error != null
      ? refresh(preservePages: _refreshTarget > 1)
      : loadMore();

  Future<void> refreshIfStale({bool invalidated = false}) async {
    if (isClosed || !_configured) return;
    if (invalidated) _freshness.invalidate();
    if (state.isLoading || state.loadingMore) {
      _pendingInvalidation = _pendingInvalidation || invalidated;
      return;
    }
    if (_freshness.isStale) await refresh(preservePages: true);
  }

  Future<void> _fetchSnapshot(int generation, int pages) async {
    final revision = _freshness.revision;
    final merged = <String, ProductData>{};
    StoreProductPage? last;
    var loadedPage = 0;
    // Three 30-item pages fit under the server's 100-item cap. Revalidate
    // atomically in aligned batches so subsequent page numbers remain valid.
    final batch = _getProducts.supportsBatchedRefresh ? pages.clamp(1, 3) : 1;
    final requests = (pages / batch).ceil();
    for (var page = 1; page <= requests; page++) {
      final result = await _getProducts(
        _marketId,
        page: page,
        pageSize: 30 * batch,
        query: _query,
        subcategoryId: _subcategoryId,
        sort: _sort,
      );
      if (isClosed || generation != _generation) return;
      switch (result) {
        case ApiFailure(:final failure):
          _emitVisible(
            state.products,
            error: failure.message,
            hasMore: state.hasMore,
            count: state.count,
          );
          _drainInvalidation(generation);
          return;
        case ApiSuccess(:final data):
          last = data;
          loadedPage = page * batch;
          for (final product in data.products) {
            merged[product.id] = product;
          }
      }
      if (!last.hasMore) {
        break;
      }
    }
    if (last == null) return;
    _page = loadedPage;
    _displayedSelectionKey = (_marketId, _query, _subcategoryId, _sort);
    _freshness.markNetworkSuccess(revision: revision);
    _emitVisible(
      List.unmodifiable(merged.values),
      hasMore: last.hasMore,
      count: last.count,
    );
    _drainInvalidation(generation);
  }

  void _drainInvalidation(int generation) {
    if (!isClosed && generation == _generation && _pendingInvalidation) {
      _pendingInvalidation = false;
      unawaited(refreshIfStale());
    }
  }

  Future<void> loadMore() async {
    if (isClosed ||
        !_configured ||
        state.isLoading ||
        state.loadingMore ||
        state.error != null ||
        !state.hasMore) {
      return;
    }
    _emitVisible(
      state.products,
      loadingMore: true,
      hasMore: state.hasMore,
      count: state.count,
    );
    await _fetch(_page + 1, _generation);
  }

  Future<void> _fetch(int page, int generation) async {
    final result = await _getProducts(
      _marketId,
      page: page,
      query: _query,
      subcategoryId: _subcategoryId,
      sort: _sort,
    );
    if (isClosed || generation != _generation) return;
    switch (result) {
      case ApiSuccess(:final data):
        _page = page;
        final merged = <String, ProductData>{
          for (final product in state.products) product.id: product,
        };
        for (final product in data.products) {
          merged[product.id] = product;
        }
        _emitVisible(
          List.unmodifiable(merged.values),
          hasMore: data.hasMore,
          count: data.count,
        );
      case ApiFailure(:final failure):
        _emitVisible(
          state.products,
          hasMore: state.hasMore,
          count: state.count,
          moreError: failure.message,
        );
    }
    _drainInvalidation(generation);
  }

  void _emitVisible(
    List<ProductData> products, {
    bool isLoading = false,
    bool loadingMore = false,
    String? error,
    String? moreError,
    bool hasMore = false,
    int count = 0,
  }) => emit(
    StoreProductsState(
      products: products,
      visibleProducts: products,
      isLoading: isLoading,
      loadingMore: loadingMore,
      error: error,
      moreError: moreError,
      hasMore: hasMore,
      count: count,
      selectionKey: _displayedSelectionKey,
    ),
  );

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
