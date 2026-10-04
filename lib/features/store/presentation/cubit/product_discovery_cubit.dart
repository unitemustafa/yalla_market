import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/data_freshness.dart';
import '../../../../core/utils/coalesced_operation.dart';
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
    DateTime Function()? now,
  }) : _getProducts = getProducts,
       _searchProducts = searchProducts,
       _getCategories = getCategories,
       _getBrands = getBrands,
       _getSelectedCity = getSelectedCity,
       _prepareDiscovery = prepareDiscovery,
       _freshness = DataFreshness(now: now),
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
  final DataFreshness _freshness;
  final _loads = CoalescedOperation();
  int? _activeRevision;

  DateTime? get lastNetworkSuccessAt => _freshness.lastNetworkSuccessAt;

  void invalidate() => _freshness.invalidate();

  Future<void> refreshIfStale() async {
    if (_freshness.isStale) await refreshSilently();
  }

  Future<void> loadDiscovery({bool force = false}) async {
    return _loads.run(() async {
      if (!force && state is ProductDiscoveryReady) {
        if (!_freshness.isStale) return;
        await _loadDiscovery(force: true, silent: true);
      } else {
        await _loadDiscovery(force: force, silent: false);
      }
    });
  }

  Future<void> refreshSilently() async {
    final generation = _requestGeneration;
    final joinedActiveLoad = _loads.isRunning;
    final invalidatedWhileLoading =
        _loads.isRunning && _activeRevision != _freshness.revision;
    await _loads.run(() => _loadDiscovery(force: true, silent: true));
    if (!isClosed &&
        (!joinedActiveLoad || generation == _requestGeneration) &&
        invalidatedWhileLoading &&
        _freshness.isStale) {
      await refreshSilently();
    }
  }

  Future<void> _loadDiscovery({
    required bool force,
    required bool silent,
  }) async {
    if (_loadingGeneration != null) return;
    if (!force && state is ProductDiscoveryReady) return;
    final generation = ++_requestGeneration;
    final revision = _freshness.revision;
    _activeRevision = revision;
    final query = state.query;
    final hadLoaded =
        state is ProductDiscoveryReady || state is ProductDiscoveryFailure;
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

      if (!silent ||
          state is ProductDiscoveryInitial ||
          state is ProductDiscoveryNeedsCity) {
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

      final productsFuture = query.isEmpty
          ? _getProducts(citySlug: selectedCity.slug, forceRefresh: force)
          : _searchProducts(query, citySlug: selectedCity.slug);
      final categoriesFuture = _getCategories(forceRefresh: force);
      final brandsFuture = _getBrands(forceRefresh: force);
      final productsResult = await productsFuture;
      final categoriesResult = await categoriesFuture;
      final brandsResult = await brandsFuture;
      if (!_isCurrent(generation)) return;
      if ([productsResult, categoriesResult, brandsResult].every(
        (result) => switch (result) {
          ApiSuccess(origin: DataOrigin.network) => true,
          _ => false,
        },
      )) {
        _freshness.markNetworkSuccess(revision: revision);
      }
      if (silent &&
          [
            productsResult,
            categoriesResult,
            brandsResult,
          ].any((result) => result is ApiFailure)) {
        if (!hadLoaded) {
          for (final result in [
            productsResult,
            categoriesResult,
            brandsResult,
          ]) {
            if (result case ApiFailure(:final failure)) {
              _emitFailure(failure.message);
              break;
            }
          }
        }
        return;
      }

      productsResult.when(
        success: (products) {
          final allProducts = _prepareDiscovery.products(
            products,
            citySlug: selectedCity.slug,
            query: query,
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
                      query: query,
                      products: allProducts,
                      categories: _filterCategories(query, countedCategories),
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
        await _refreshDiscoveryInPlace(
          generation,
          selectedCity,
          revision,
          query,
        );
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
    int revision,
    String query,
  ) async {
    final productsFuture = query.isEmpty
        ? _getProducts(citySlug: selectedCity.slug, forceRefresh: true)
        : _searchProducts(query, citySlug: selectedCity.slug);
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
      query: query,
    );
    final categories = _prepareDiscovery.categoriesWithProductCounts(
      categories: categoriesResult.data,
      products: products,
      citySlug: selectedCity.slug,
    );
    emit(
      ProductDiscoveryReady(
        query: query,
        products: products,
        categories: _filterCategories(query, categories),
        brands: brandsResult.data,
        city: selectedCity,
      ),
    );
    if ([
      productsResult,
      categoriesResult,
      brandsResult,
    ].every((result) => result.origin == DataOrigin.network)) {
      _freshness.markNetworkSuccess(revision: revision);
    }
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
    _loads.reset();
    _freshness.invalidate();
    _requestGeneration++;
    _loadingGeneration = null;
    emit(const ProductDiscoveryInitial());
  }

  bool _isCurrent(int generation) {
    return generation == _requestGeneration && !isClosed;
  }
}
