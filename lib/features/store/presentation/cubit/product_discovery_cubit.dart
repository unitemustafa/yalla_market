import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../../location/domain/entities/city_data.dart';
import '../../../location/domain/usecases/location_usecases.dart';
import '../../domain/entities/brand_data.dart';
import '../../domain/entities/category_data.dart';
import '../../domain/entities/product_data.dart';
import '../../domain/usecases/get_brands_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/prepare_product_discovery_usecase.dart';
import '../../domain/usecases/search_products_usecase.dart';
import 'product_discovery_state.dart';

class ProductDiscoveryCubit extends Cubit<ProductDiscoveryState> {
  ProductDiscoveryCubit({
    required GetProductsUseCase getProducts,
    required SearchProductsUseCase searchProducts,
    required GetCategoriesUseCase getCategories,
    required GetBrandsUseCase getBrands,
    required GetSelectedCityUseCase getSelectedCity,
    PrepareProductDiscoveryUseCase prepareDiscovery =
        const PrepareProductDiscoveryUseCase(),
  }) : _getProducts = getProducts,
       _searchProducts = searchProducts,
       _getCategories = getCategories,
       _getBrands = getBrands,
       _getSelectedCity = getSelectedCity,
       _prepareDiscovery = prepareDiscovery,
       super(const ProductDiscoveryInitial()) {
    loadDiscovery();
  }

  final GetProductsUseCase _getProducts;
  final SearchProductsUseCase _searchProducts;
  final GetCategoriesUseCase _getCategories;
  final GetBrandsUseCase _getBrands;
  final GetSelectedCityUseCase _getSelectedCity;
  final PrepareProductDiscoveryUseCase _prepareDiscovery;
  int? _loadingGeneration;
  int _requestGeneration = 0;

  Future<void> loadDiscovery({bool force = false}) async {
    return _loadDiscovery(force: force, silent: false);
  }

  Future<void> refreshSilently() async {
    return _loadDiscovery(force: true, silent: true);
  }

  Future<void> _loadDiscovery({
    required bool force,
    required bool silent,
  }) async {
    if (_loadingGeneration != null) return;
    if (!force && state is ProductDiscoveryReady) return;
    final generation = ++_requestGeneration;
    _loadingGeneration = generation;

    try {
      final cityResult = await _getSelectedCity();
      if (!_isCurrent(generation)) return;
      final selectedCity = cityResult.when(
        success: (city) => city,
        failure: (_) => null,
      );

      if (selectedCity == null) {
        emit(const ProductDiscoveryNeedsCity());
        return;
      }

      if (!silent || state.products.isEmpty) {
        emit(
          ProductDiscoveryLoading(
            query: state.query,
            products: state.products,
            categories: state.categories,
            brands: state.brands,
            city: selectedCity,
          ),
        );
      }

      final productsFuture = _getProducts(
        citySlug: selectedCity.slug,
        forceRefresh: force,
      );
      final categoriesFuture = _getCategories(forceRefresh: force);
      final brandsFuture = _getBrands(forceRefresh: force);
      final productsResult = await productsFuture;
      final categoriesResult = await categoriesFuture;
      final brandsResult = await brandsFuture;
      if (!_isCurrent(generation)) return;
      if (silent &&
          [
            productsResult,
            categoriesResult,
            brandsResult,
          ].any((result) => result is ApiFailure)) {
        return;
      }

      productsResult.when(
        success: (products) {
          final allProducts = _prepareDiscovery.products(
            products,
            citySlug: selectedCity.slug,
          );

          categoriesResult.when(
            success: (categories) {
              final countedCategories = _prepareDiscovery
                  .categoriesWithProductCounts(
                    categories: categories,
                    products: allProducts,
                    citySlug: selectedCity.slug,
                  );

              brandsResult.when(
                success: (brands) {
                  emit(
                    ProductDiscoveryReady(
                      query: '',
                      products: allProducts,
                      categories: countedCategories,
                      brands: brands,
                      city: selectedCity,
                    ),
                  );
                },
                failure: (failure) => _emitFailure(failure.message),
              );
            },
            failure: (failure) => _emitFailure(failure.message),
          );
        },
        failure: (failure) => _emitFailure(failure.message),
      );
      final servedCache = [productsResult, categoriesResult, brandsResult].any(
        (result) => switch (result) {
          ApiSuccess(origin: DataOrigin.cache) => true,
          _ => false,
        },
      );
      if (!force && servedCache && state is ProductDiscoveryReady) {
        await _refreshDiscoveryInPlace(generation, selectedCity);
      }
    } finally {
      if (_loadingGeneration == generation) {
        _loadingGeneration = null;
      }
    }
  }

  Future<void> _refreshDiscoveryInPlace(
    int generation,
    CityData selectedCity,
  ) async {
    final productsFuture = _getProducts(
      citySlug: selectedCity.slug,
      forceRefresh: true,
    );
    final categoriesFuture = _getCategories(forceRefresh: true);
    final brandsFuture = _getBrands(forceRefresh: true);
    final productsResult = await productsFuture;
    final categoriesResult = await categoriesFuture;
    final brandsResult = await brandsFuture;
    if (!_isCurrent(generation)) return;
    if (productsResult is! ApiSuccess<List<ProductData>> ||
        categoriesResult is! ApiSuccess<List<CategoryData>> ||
        brandsResult is! ApiSuccess<List<BrandData>>) {
      return;
    }
    final products = _prepareDiscovery.products(
      productsResult.data,
      citySlug: selectedCity.slug,
    );
    final categories = _prepareDiscovery.categoriesWithProductCounts(
      categories: categoriesResult.data,
      products: products,
      citySlug: selectedCity.slug,
    );
    emit(
      ProductDiscoveryReady(
        query: '',
        products: products,
        categories: categories,
        brands: brandsResult.data,
        city: selectedCity,
      ),
    );
  }

  Future<void> search(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery == state.query && state is ProductDiscoveryReady) {
      return;
    }

    final generation = ++_requestGeneration;

    final cityResult = await _getSelectedCity();
    if (!_isCurrent(generation)) return;
    final selectedCity = cityResult.when(
      success: (city) => city,
      failure: (_) => null,
    );

    if (selectedCity == null) {
      emit(const ProductDiscoveryNeedsCity());
      return;
    }

    emit(
      ProductDiscoveryLoading(
        query: normalizedQuery,
        products: state.products,
        categories: state.categories,
        brands: state.brands,
        city: selectedCity,
      ),
    );

    final productsResult = normalizedQuery.isEmpty
        ? await _getProducts(citySlug: selectedCity.slug)
        : await _searchProducts(normalizedQuery, citySlug: selectedCity.slug);
    if (!_isCurrent(generation)) return;

    productsResult.when(
      success: (products) {
        final allProducts = _prepareDiscovery.products(
          products,
          citySlug: selectedCity.slug,
          query: normalizedQuery,
        );

        emit(
          ProductDiscoveryReady(
            query: normalizedQuery,
            products: allProducts,
            categories: _filterCategories(normalizedQuery, state.categories),
            brands: state.brands,
            city: selectedCity,
          ),
        );
      },
      failure: (failure) =>
          _emitFailure(failure.message, query: normalizedQuery),
    );
  }

  List<CategoryData> _filterCategories(
    String query,
    List<CategoryData> categories,
  ) {
    if (query.isEmpty) return categories;
    return categories
        .where((category) => category.matches(query))
        .toList(growable: false);
  }

  void _emitFailure(String message, {String? query}) {
    emit(
      ProductDiscoveryFailure(
        message,
        query: query ?? state.query,
        products: state.products,
        categories: state.categories,
        brands: state.brands,
        city: state.city,
      ),
    );
  }

  void clearSession() {
    _requestGeneration++;
    _loadingGeneration = null;
    emit(const ProductDiscoveryInitial());
  }

  bool _isCurrent(int generation) {
    return generation == _requestGeneration && !isClosed;
  }
}
