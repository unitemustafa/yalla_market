import 'package:get_it/get_it.dart';
import '../domain/repositories/store_products_repository.dart';
import '../domain/usecases/get_store_products_usecase.dart';
import '../data/repositories/store_products_remote_repository_impl.dart';
import '../data/repositories/store_products_demo_repository.dart';
import '../presentation/cubit/store_products_cubit.dart';
import '../domain/usecases/get_market_listing_usecase.dart';
import '../presentation/cubit/market_listing_cubit.dart';
import '../data/repositories/market_listing_demo_repository.dart';
import '../../../core/domain/computation_executor.dart';
import '../../../core/computation/catalog_computation_executor.dart';

import '../../../core/cache/persistent_json_cache.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_store.dart';
import '../data/datasources/pending_order_request_store.dart';
import '../data/mapping/storefront_decoder.dart';
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
import '../domain/usecases/prepare_product_results_usecase.dart';
import '../presentation/cubit/product_results_cubit.dart';

/// Also used by the reusable results widget in isolated widget tests.
void registerProductResultsDependencies(GetIt sl) {
  if (!sl.isRegistered<ComputationExecutor>()) {
    sl.registerLazySingleton<ComputationExecutor>(
      () => const CatalogComputationExecutor(),
    );
  }
  if (!sl.isRegistered<PrepareProductResultsUseCase>()) {
    sl.registerLazySingleton(
      () => PrepareProductResultsUseCase(executor: sl<ComputationExecutor>()),
    );
  }
  if (!sl.isRegistered<ProductResultsCubit>()) {
    sl.registerFactory(
      () => ProductResultsCubit(sl<PrepareProductResultsUseCase>()),
    );
  }
}

void registerStoreDependencies(GetIt sl, {bool? useDemoRepositories}) {
  registerProductResultsDependencies(sl);
  if (!sl.isRegistered<StorefrontDecoder>()) {
    sl.registerLazySingleton(
      () => StorefrontDecoder(executor: sl<ComputationExecutor>()),
    );
  }
  final useDemo = useDemoRepositories ?? AppEnvironment.useDemoRepositories;
  if (!sl.isRegistered<StoreProductsRepository>()) {
    sl.registerLazySingleton<StoreProductsRepository>(
      () => useDemo
          ? StoreProductsDemoRepository(sl<StoreRepository>())
          : StoreProductsRemoteRepositoryImpl(sl<ApiClient>()),
    );
  }
  if (!sl.isRegistered<GetStoreProductsUseCase>()) {
    sl.registerLazySingleton(
      () => GetStoreProductsUseCase(sl<StoreProductsRepository>()),
    );
  }
  if (!sl.isRegistered<StoreProductsCubit>()) {
    sl.registerFactory(() => StoreProductsCubit(sl<GetStoreProductsUseCase>()));
  }

  if (!useDemo && !sl.isRegistered<PendingOrderRequestStore>()) {
    sl.registerLazySingleton<PendingOrderRequestStore>(
      () => SecurePendingOrderRequestStore(sl<TokenStore>()),
    );
  }

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
              decoder: sl<StorefrontDecoder>(),
              cache: sl<PersistentJsonCache>(),
              getSelectedCity: sl<GetSelectedCityUseCase>(),
            ),
    );
  }
  if (!sl.isRegistered<GetStoreUseCase>()) {
    sl.registerLazySingleton(() => GetStoreUseCase(sl<StoreRepository>()));
  }
  if (!sl.isRegistered<MarketListingRepository>()) {
    sl.registerLazySingleton<MarketListingRepository>(() {
      final repository = sl<StoreRepository>();
      return repository is MarketListingRepository
          ? repository as MarketListingRepository
          : MarketListingDemoRepository(repository);
    });
  }
  if (!sl.isRegistered<GetMarketListingUseCase>()) {
    sl.registerLazySingleton(
      () => GetMarketListingUseCase(sl<MarketListingRepository>()),
    );
  }
  if (!sl.isRegistered<MarketListingCubit>()) {
    sl.registerFactory(() => MarketListingCubit(sl<GetMarketListingUseCase>()));
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
            : OrderRemoteRepositoryImpl(
                sl<ApiClient>(),
                requestStore: sl<PendingOrderRequestStore>(),
              ),
      ),
    );
  }
  if (!sl.isRegistered<PreviewOrderUseCase>()) {
    sl.registerLazySingleton(
      () => PreviewOrderUseCase(
        useDemo
            ? sl<OrderRepository>()
            : OrderRemoteRepositoryImpl(
                sl<ApiClient>(),
                requestStore: sl<PendingOrderRequestStore>(),
              ),
      ),
    );
  }
  if (!sl.isRegistered<GetMyOrdersUseCase>()) {
    sl.registerLazySingleton(
      () => GetMyOrdersUseCase(
        useDemo
            ? sl<OrderRepository>()
            : OrderRemoteRepositoryImpl(
                sl<ApiClient>(),
                requestStore: sl<PendingOrderRequestStore>(),
              ),
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
            : OrderRemoteRepositoryImpl(
                sl<ApiClient>(),
                requestStore: sl<PendingOrderRequestStore>(),
              ),
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
