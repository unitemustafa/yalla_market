import 'package:flutter_bloc/flutter_bloc.dart';

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

  Future<void> loadProducts({bool force = false}) async {
    if (state is ProductCatalogLoading) return;
    if (!force && state is ProductCatalogReady) return;
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

    emit(const ProductCatalogLoading());

    final result = await _getProductsUseCase(
      citySlug: selectedCity.slug,
      forceRefresh: force,
    );
    if (!_isCurrent(generation)) return;
    result.when(
      success: (products) {
        emit(ProductCatalogReady(products, city: selectedCity));
      },
      failure: (failure) {
        emit(ProductCatalogFailure(failure.message));
      },
    );
  }

  void clearSession() {
    _generation++;
    emit(const ProductCatalogInitial());
  }

  bool _isCurrent(int generation) {
    return generation == _generation && !isClosed;
  }
}
