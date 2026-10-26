import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/data_page.dart';
import '../../network/api_result.dart';

class PagedListState<T> {
  const PagedListState({
    this.items = const [],
    this.page,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.moreError,
  });
  final List<T> items;
  final DataPage<T>? page;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String? moreError;
  bool get hasMore => page?.hasMore ?? false;
}

/// Owns a route's query and ignores responses from replaced queries/accounts.
class PagedListCubit<T, Q> extends Cubit<PagedListState<T>> {
  PagedListCubit(this._load, {required String Function(T) idOf})
    : _idOf = idOf,
      super(PagedListState<T>());
  final LoadPageUseCase<T, Q> _load;
  final String Function(T) _idOf;
  Q? _query;
  bool _configured = false;
  int _generation = 0;
  int _page = 0;
  DateTime? _syncedAt;
  bool _pendingRefresh = false;
  void _drainRefresh() {
    if (_pendingRefresh && !isClosed) {
      _pendingRefresh = false;
      unawaited(refresh());
    }
  }

  Future<void> refreshIfStale() async {
    if (_syncedAt == null ||
        DateTime.now().difference(_syncedAt!) >= const Duration(seconds: 60)) {
      await refresh();
    }
  }

  Future<void> configure(Q query, {bool force = false}) async {
    if (isClosed || (!force && _configured && query == _query)) {
      return;
    }
    _query = query;
    _configured = true;
    final generation = ++_generation;
    _page = 0;
    _syncedAt = null;
    _pendingRefresh = false;
    emit(PagedListState<T>(loading: true));
    await _fetch(1, generation, query);
  }

  Future<void> refresh() async {
    if (!_configured || isClosed) {
      return;
    }
    if (state.loading || state.loadingMore) {
      _pendingRefresh = true;
      return;
    }
    final generation = ++_generation;
    final pages = _page < 1 ? 1 : _page;
    emit(
      PagedListState<T>(items: state.items, page: state.page, loading: true),
    );
    final merged = <String, T>{};
    DataPage<T>? last;
    var loaded = 0;
    for (var page = 1; page <= pages; page++) {
      final result = await _load(_query as Q, page: page);
      if (isClosed || generation != _generation) {
        return;
      }
      switch (result) {
        case ApiFailure(:final failure):
          emit(
            PagedListState<T>(
              items: state.items,
              page: state.page,
              error: failure.message,
            ),
          );
          _drainRefresh();
          return;
        case ApiSuccess(:final data):
          last = data;
          loaded = page;
          for (final item in data.items) {
            merged[_idOf(item)] = item;
          }
      }
      if (!last.hasMore) break;
    }
    _page = loaded;
    _syncedAt = DateTime.now();
    emit(
      PagedListState<T>(items: List.unmodifiable(merged.values), page: last),
    );
    _drainRefresh();
  }

  Future<void> loadMore() async {
    if (isClosed ||
        !_configured ||
        state.loading ||
        state.loadingMore ||
        !state.hasMore) {
      return;
    }
    emit(
      PagedListState<T>(
        items: state.items,
        page: state.page,
        loadingMore: true,
      ),
    );
    await _fetch(_page + 1, _generation, _query as Q);
  }

  Future<void> _fetch(int page, int generation, Q query) async {
    final result = await _load(query, page: page);
    if (isClosed || generation != _generation) {
      return;
    }
    switch (result) {
      case ApiSuccess(:final data):
        final merged = <String, T>{
          for (final item in state.items) _idOf(item): item,
        };
        for (final item in data.items) {
          merged[_idOf(item)] = item;
        }
        _page = page;
        _syncedAt = DateTime.now();
        emit(
          PagedListState<T>(
            items: List.unmodifiable(merged.values),
            page: data,
          ),
        );
      case ApiFailure(:final failure):
        emit(
          PagedListState<T>(
            items: state.items,
            page: state.page,
            error: page == 1 ? failure.message : null,
            moreError: page == 1 ? null : failure.message,
          ),
        );
    }
    _drainRefresh();
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
