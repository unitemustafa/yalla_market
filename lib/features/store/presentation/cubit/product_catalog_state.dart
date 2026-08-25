import '../../domain/entities/product_data.dart';
import '../../../location/domain/entities/city_data.dart';

sealed class ProductCatalogState {
  const ProductCatalogState();
}

final class ProductCatalogInitial extends ProductCatalogState {
  const ProductCatalogInitial();
}

final class ProductCatalogLoading extends ProductCatalogState {
  const ProductCatalogLoading();
}

final class ProductCatalogNeedsCity extends ProductCatalogState {
  const ProductCatalogNeedsCity();
}

final class ProductCatalogReady extends ProductCatalogState {
  const ProductCatalogReady(
    this.products, {
    required this.city,
    this.refreshError,
  });

  final List<ProductData> products;
  final CityData city;
  final String? refreshError;
}

final class ProductCatalogFailure extends ProductCatalogState {
  const ProductCatalogFailure(this.message);

  final String message;
}
