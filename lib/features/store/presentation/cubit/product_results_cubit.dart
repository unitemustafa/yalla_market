import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/bounded_memoizer.dart';
import '../../../../core/network/api_result.dart';

import '../../domain/entities/product_data.dart';
import '../../domain/usecases/prepare_product_results_usecase.dart';

sealed class ProductResultsState {
  const ProductResultsState();
}

final class ProductResultsReady extends ProductResultsState {
  const ProductResultsReady({
    this.products = const [],
    this.query = '',
    this.sortOption = 'Name',
    this.page = 0,
    this.pageSize = 10,
    this.isPreparing = false,
    this.preparationError,
    this.categoryKey,
  });

  final List<ProductData> products;
  final String query;
  final String sortOption;
  final int page;
  final int pageSize;
  final bool isPreparing;
  final String? preparationError;
  final Object? categoryKey;

  int get totalPages =>
      products.isEmpty ? 1 : (products.length / pageSize).ceil();
  int get start => page * pageSize;
  int get itemCount => (products.length - start).clamp(0, pageSize);
  ProductData itemAt(int index) => products[start + index];
}

final class ProductResultsFailure extends ProductResultsState {
  const ProductResultsFailure(this.message);
  final String message;
}

class ProductResultsCubit extends Cubit<ProductResultsState> {
  ProductResultsCubit(this._prepare) : super(const ProductResultsReady());

  final PrepareProductResultsUseCase _prepare;
  List<ProductData>? _source;
  String _query = '';
  String _sortOption = 'Name';
  String? _subcategoryId;
  Object? _categoryKey;

  int _pageSize = 10;
  int _generation = 0;
  bool _pending = false;
  bool _valid = false;
  bool _resetPage = false;
  // Only two recent categories for the current input snapshot. This retains
  // result data, never widget trees, and avoids a fresh isolate on each revisit.
  final _categoryResults =
      BoundedMemoizer<(String?, Object?), List<ProductData>>(capacity: 2);

  Future<void> update({
    required List<ProductData> products,
    required String query,
    required String sortOption,

    required int pageSize,
    String? subcategoryId,
    Object? categoryKey,
  }) async {
    if (isClosed) return;
    assert(pageSize > 0);
    final normalizedQuery = query.trim();
    final normalizedCategory = subcategoryId?.trim();
    final resetPage = _query != normalizedQuery || _sortOption != sortOption;
    final inputsChanged = !identical(_source, products) || resetPage;
    final recalculate =
        inputsChanged ||
        _subcategoryId != normalizedCategory ||
        _categoryKey != categoryKey;
    final previous = state;

    _pageSize = pageSize;
    if (!recalculate && (_valid || _pending)) {
      if (previous is ProductResultsReady && previous.pageSize != pageSize) {
        _emitPage(previous, previous.page);
      }
      return;
    }

    final generation = ++_generation;
    _pending = true;
    _valid = false;
    _resetPage = _resetPage || resetPage || previous is! ProductResultsReady;
    if (inputsChanged) _categoryResults.clear();
    _source = products;
    _query = normalizedQuery;
    _sortOption = sortOption;

    _subcategoryId = normalizedCategory;
    _categoryKey = categoryKey;
    final cached = _categoryResults.lookup((_subcategoryId, _categoryKey));
    if (cached != null) {
      _commitResults(cached);
      return;
    }
    if (previous is ProductResultsReady) {
      final retained = previous.products;
      final totalPages = retained.isEmpty
          ? 1
          : (retained.length / pageSize).ceil();
      emit(
        ProductResultsReady(
          products: retained,
          query: previous.query,
          sortOption: previous.sortOption,
          page: previous.page.clamp(0, totalPages - 1),
          pageSize: pageSize,
          isPreparing: true,
          categoryKey: previous.categoryKey,
        ),
      );
    } else {
      emit(ProductResultsReady(pageSize: pageSize, isPreparing: true));
    }
    final result = await _prepare(
      products,
      query: _query,
      sortOption: _sortOption,
      subcategoryId: _subcategoryId,
    );
    if (isClosed || generation != _generation) return;
    _pending = false;
    final current = state;
    switch (result) {
      case ApiSuccess(:final data):
        _categoryResults.store((_subcategoryId, _categoryKey), data);
        _commitResults(data);
      case ApiFailure(:final failure):
        if (current is ProductResultsReady && current.products.isNotEmpty) {
          emit(
            ProductResultsReady(
              products: current.products,
              query: current.query,
              sortOption: current.sortOption,
              page: current.page,
              pageSize: _pageSize,
              preparationError: failure.message,
              categoryKey: current.categoryKey,
            ),
          );
        } else {
          emit(ProductResultsFailure(failure.message));
        }
    }
  }

  void _commitResults(List<ProductData> data) {
    _pending = false;
    _valid = true;
    final current = state;
    final totalPages = data.isEmpty ? 1 : (data.length / _pageSize).ceil();
    final page = _resetPage || current is! ProductResultsReady
        ? 0
        : current.page.clamp(0, totalPages - 1);
    _resetPage = false;
    emit(
      ProductResultsReady(
        products: data,
        query: _query,
        sortOption: _sortOption,
        page: page,
        pageSize: _pageSize,
        categoryKey: _categoryKey,
      ),
    );
  }

  @override
  Future<void> close() {
    _categoryResults.clear();
    return super.close();
  }

  void selectPage(int page) {
    final current = state;
    if (current is! ProductResultsReady) return;
    final safePage = page.clamp(0, current.totalPages - 1);
    if (safePage == current.page) return;
    _emitPage(current, safePage);
  }

  void _emitPage(ProductResultsReady current, int page) {
    final totalPages = current.products.isEmpty
        ? 1
        : (current.products.length / _pageSize).ceil();
    emit(
      ProductResultsReady(
        products: current.products,
        query: current.query,
        sortOption: current.sortOption,
        page: page.clamp(0, totalPages - 1),
        pageSize: _pageSize,
        isPreparing: current.isPreparing,
        preparationError: current.preparationError,
        categoryKey: current.categoryKey,
      ),
    );
  }
}
