import 'package:get_it/get_it.dart';

import '../../../core/cache/persistent_json_cache.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../features/location/domain/usecases/location_usecases.dart';
import '../../../features/store/data/repositories/order_unavailable_repository_impl.dart';
import '../../../features/store/data/demo/demo_order_history_supplement.dart';
import '../../../features/store/data/demo/demo_market_shop_catalog.dart';
import '../../../features/store/data/demo/demo_product_discovery_supplement.dart';
import '../../../features/store/data/repositories/order_remote_repository_impl.dart';
import '../../../features/store/data/repositories/product_remote_repository_impl.dart';
import '../../../features/store/data/repositories/product_repository_impl.dart';
import '../../../features/store/data/repositories/store_remote_repository_impl.dart';
import '../../../features/store/data/repositories/store_repository_impl.dart';
import '../../../features/store/data/repositories/shipping_company_remote_repository_impl.dart';
import '../../../features/store/domain/repositories/order_repository.dart';
import '../../../features/store/domain/repositories/product_repository.dart';
import '../../../features/store/domain/repositories/store_repository.dart';
import '../../../features/store/domain/repositories/shipping_company_repository.dart';
import '../../../features/store/domain/services/market_shop_catalog.dart';
import '../../../features/store/domain/usecases/create_order_usecase.dart';
import '../../../features/store/domain/usecases/accept_delivery_quote_usecase.dart';
import '../../../features/store/domain/usecases/get_brands_usecase.dart';
import '../../../features/store/domain/usecases/get_categories_usecase.dart';
import '../../../features/store/domain/usecases/get_classification_markets_usecase.dart';
import '../../../features/store/domain/usecases/get_market_usecase.dart';
import '../../../features/store/domain/usecases/get_my_orders_usecase.dart';
import '../../../features/store/domain/usecases/get_product_usecase.dart';
import '../../../features/store/domain/usecases/get_products_usecase.dart';
import '../../../features/store/domain/usecases/preview_order_usecase.dart';
import '../../../features/store/domain/usecases/prepare_product_discovery_usecase.dart';
import '../../../features/store/domain/usecases/search_products_usecase.dart';
import '../../../features/store/domain/usecases/get_store_usecase.dart';
import '../../../features/store/domain/usecases/get_shipping_companies_usecase.dart';
import '../../../features/store/presentation/cubit/checkout_cubit.dart';
import '../../../features/store/presentation/cubit/order_history_cubit.dart';
import '../../../features/store/presentation/cubit/product_catalog_cubit.dart';
import '../../../features/store/presentation/cubit/product_discovery_cubit.dart';
import '../../../features/store/presentation/cubit/store_cubit.dart';

void registerStoreDependencies(GetIt sl, {bool? useDemoRepositories}) {
  final useDemo = useDemoRepositories ?? AppEnvironment.useDemoRepositories;

  if (!sl.isRegistered<MarketShopCatalog>()) {
    sl.registerLazySingleton<MarketShopCatalog>(
      () => useDemo
          ? const DemoMarketShopCatalog()
          : const EmptyMarketShopCatalog(),
    );
  }

  if (!sl.isRegistered<ProductRepository>()) {
    sl.registerLazySingleton<ProductRepository>(
      () => useDemo
          ? ProductRepositoryImpl()
          : ProductRemoteRepositoryImpl(
              sl<ApiClient>(),
              cache: sl<PersistentJsonCache>(),
              getSelectedCity: sl<GetSelectedCityUseCase>(),
            ),
    );
  }
  if (!sl.isRegistered<GetProductsUseCase>()) {
    sl.registerLazySingleton(() => GetProductsUseCase(sl<ProductRepository>()));
  }
  if (!sl.isRegistered<GetProductUseCase>()) {
    sl.registerLazySingleton(() => GetProductUseCase(sl<ProductRepository>()));
  }
  if (!sl.isRegistered<SearchProductsUseCase>()) {
    sl.registerLazySingleton(
      () => SearchProductsUseCase(sl<ProductRepository>()),
    );
  }
  if (!sl.isRegistered<GetCategoriesUseCase>()) {
    sl.registerLazySingleton(
      () => GetCategoriesUseCase(sl<ProductRepository>()),
    );
  }
  if (!sl.isRegistered<GetBrandsUseCase>()) {
    sl.registerLazySingleton(() => GetBrandsUseCase(sl<ProductRepository>()));
  }
  if (!sl.isRegistered<ProductDiscoverySupplement>()) {
    sl.registerLazySingleton<ProductDiscoverySupplement>(
      () => useDemo
          ? const DemoProductDiscoverySupplement()
          : const EmptyProductDiscoverySupplement(),
    );
  }
  if (!sl.isRegistered<PrepareProductDiscoveryUseCase>()) {
    sl.registerLazySingleton(
      () => PrepareProductDiscoveryUseCase(
        supplement: sl<ProductDiscoverySupplement>(),
      ),
    );
  }
  if (!sl.isRegistered<StoreRepository>()) {
    sl.registerLazySingleton<StoreRepository>(
      () => useDemo
          ? StoreRepositoryImpl()
          : StoreRemoteRepositoryImpl(
              sl<ApiClient>(),
              cache: sl<PersistentJsonCache>(),
              getSelectedCity: sl<GetSelectedCityUseCase>(),
            ),
    );
  }
  if (!sl.isRegistered<GetStoreUseCase>()) {
    sl.registerLazySingleton(() => GetStoreUseCase(sl<StoreRepository>()));
  }
  if (!sl.isRegistered<GetMarketUseCase>()) {
    sl.registerLazySingleton(() => GetMarketUseCase(sl<StoreRepository>()));
  }
  if (!sl.isRegistered<GetClassificationMarketsUseCase>()) {
    sl.registerLazySingleton(
      () => GetClassificationMarketsUseCase(sl<StoreRepository>()),
    );
  }
  if (!sl.isRegistered<StoreCubit>()) {
    sl.registerFactory(
      () => StoreCubit(
        sl<GetStoreUseCase>(),
        getMarket: sl<GetMarketUseCase>(),
        getClassificationMarkets: sl<GetClassificationMarketsUseCase>(),
      ),
    );
  }
  if (!sl.isRegistered<ProductCatalogCubit>()) {
    sl.registerFactory(
      () => ProductCatalogCubit(
        sl<GetProductsUseCase>(),
        sl<GetSelectedCityUseCase>(),
      ),
    );
  }
  if (!sl.isRegistered<ProductDiscoveryCubit>()) {
    sl.registerFactory(
      () => ProductDiscoveryCubit(
        getProducts: sl<GetProductsUseCase>(),
        searchProducts: sl<SearchProductsUseCase>(),
        getCategories: sl<GetCategoriesUseCase>(),
        getBrands: sl<GetBrandsUseCase>(),
        getSelectedCity: sl<GetSelectedCityUseCase>(),
        prepareDiscovery: sl<PrepareProductDiscoveryUseCase>(),
      ),
    );
  }
  if (!sl.isRegistered<OrderRepository>()) {
    sl.registerLazySingleton<OrderRepository>(
      OrderUnavailableRepositoryImpl.new,
    );
  }
  if (!sl.isRegistered<ShippingCompanyRepository>()) {
    sl.registerLazySingleton<ShippingCompanyRepository>(
      () => ShippingCompanyRemoteRepositoryImpl(sl<ApiClient>()),
    );
  }
  if (!sl.isRegistered<GetShippingCompaniesUseCase>()) {
    sl.registerLazySingleton(
      () => GetShippingCompaniesUseCase(sl<ShippingCompanyRepository>()),
    );
  }
  if (!sl.isRegistered<CreateOrderUseCase>()) {
    sl.registerLazySingleton(
      () => CreateOrderUseCase(
        useDemo
            ? sl<OrderRepository>()
            : OrderRemoteRepositoryImpl(sl<ApiClient>()),
      ),
    );
  }
  if (!sl.isRegistered<PreviewOrderUseCase>()) {
    sl.registerLazySingleton(
      () => PreviewOrderUseCase(
        useDemo
            ? sl<OrderRepository>()
            : OrderRemoteRepositoryImpl(sl<ApiClient>()),
      ),
    );
  }
  if (!sl.isRegistered<GetMyOrdersUseCase>()) {
    sl.registerLazySingleton(
      () => GetMyOrdersUseCase(
        useDemo
            ? sl<OrderRepository>()
            : OrderRemoteRepositoryImpl(sl<ApiClient>()),
        supplement: useDemo
            ? const DemoOrderHistorySupplement()
            : const EmptyOrderHistorySupplement(),
      ),
    );
  }
  if (!sl.isRegistered<AcceptDeliveryQuoteUseCase>()) {
    sl.registerLazySingleton(
      () => AcceptDeliveryQuoteUseCase(
        useDemo
            ? sl<OrderRepository>()
            : OrderRemoteRepositoryImpl(sl<ApiClient>()),
      ),
    );
  }
  if (!sl.isRegistered<CheckoutCubit>()) {
    sl.registerFactory(
      () => CheckoutCubit(sl<CreateOrderUseCase>(), sl<PreviewOrderUseCase>()),
    );
  }
  if (!sl.isRegistered<OrderHistoryCubit>()) {
    sl.registerFactory(
      () => OrderHistoryCubit(
        sl<GetMyOrdersUseCase>(),
        sl<AcceptDeliveryQuoteUseCase>(),
      ),
    );
  }
}
