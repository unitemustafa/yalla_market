import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../../location/domain/usecases/location_usecases.dart';
import '../../domain/usecases/get_products_usecase.dart';
import 'product_catalog_state.dart';

class ProductCatalogCubit extends Cubit<ProductCatalogState> {
  ProductCatalogCubit(this._getProductsUseCase, this._getSelectedCityUseCase)
    : super(const ProductCatalogInitial()) {
    loadProducts();
  }

  final GetProductsUseCase _getProductsUseCase;
  final GetSelectedCityUseCase _getSelectedCityUseCase;
  int _generation = 0;
  Future<void>? _loadInFlight;

  Future<void> loadProducts({bool force = false}) async {
    final activeLoad = _loadInFlight;
    if (activeLoad != null) return activeLoad;
    if (!force && state is ProductCatalogReady) return;
    final operation = _load(force: force, silent: false);
    _loadInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_loadInFlight, operation)) _loadInFlight = null;
    }
  }

  Future<void> refreshSilently() async {
    final activeLoad = _loadInFlight;
    if (activeLoad != null) return activeLoad;
    final operation = _load(force: true, silent: true);
    _loadInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_loadInFlight, operation)) _loadInFlight = null;
    }
  }

  Future<void> _load({required bool force, required bool silent}) async {
    final previous = state is ProductCatalogReady
        ? state as ProductCatalogReady
        : null;
    final generation = ++_generation;

    final cityResult = await _getSelectedCityUseCase();
    if (!_isCurrent(generation)) return;
    final selectedCity = cityResult.when(
      success: (city) => city,
      failure: (_) => null,
    );

    if (selectedCity == null) {
      emit(const ProductCatalogNeedsCity());
      return;
    }

    if (previous == null) emit(const ProductCatalogLoading());

    final result = await _getProductsUseCase(
      citySlug: selectedCity.slug,
      forceRefresh: force,
    );
    if (!_isCurrent(generation)) return;
    switch (result) {
      case ApiSuccess(:final data, :final origin):
        emit(ProductCatalogReady(data, city: selectedCity));
        if (!force && origin == DataOrigin.cache) {
          final refreshed = await _getProductsUseCase(
            citySlug: selectedCity.slug,
            forceRefresh: true,
          );
          if (!_isCurrent(generation)) return;
          if (refreshed case ApiSuccess(:final data)) {
            emit(ProductCatalogReady(data, city: selectedCity));
          }
        }
      case ApiFailure(:final failure):
        if (previous == null) {
          emit(ProductCatalogFailure(failure.message));
        } else if (!silent) {
          emit(
            ProductCatalogReady(
              previous.products,
              city: previous.city,
              refreshError: failure.message,
            ),
          );
        }
    }
  }

  void clearSession() {
    _generation++;
    _loadInFlight = null;
    emit(const ProductCatalogInitial());
  }

  bool _isCurrent(int generation) {
    return generation == _generation && !isClosed;
  }
}
