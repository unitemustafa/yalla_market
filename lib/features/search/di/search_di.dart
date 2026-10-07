import 'package:get_it/get_it.dart';

import '../../../core/cache/persistent_json_cache.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../location/domain/usecases/location_usecases.dart';
import '../../store/domain/repositories/product_repository.dart';
import '../../store/domain/repositories/store_repository.dart';
import '../../store/domain/services/market_shop_catalog.dart';
import '../data/repositories/catalog_search_demo_repository.dart';
import '../data/repositories/catalog_search_remote_repository.dart';
import '../domain/repositories/catalog_search_repository.dart';
import '../domain/usecases/search_catalog_usecase.dart';
import '../presentation/cubit/catalog_search_cubit.dart';

void registerSearchDependencies(GetIt sl) {
  sl.registerLazySingleton<CatalogSearchRepository>(
    () => AppEnvironment.useDemoRepositories
        ? CatalogSearchDemoRepository(
            sl<ProductRepository>(),
            sl<StoreRepository>(),
            sl<MarketShopCatalog>(),
          )
        : CatalogSearchRemoteRepository(
            sl<ApiClient>(),
            cache: sl<PersistentJsonCache>(),
          ),
  );
  sl.registerLazySingleton(
    () => SearchCatalogUseCase(sl<CatalogSearchRepository>()),
  );
  sl.registerFactory(
    () => CatalogSearchCubit(
      sl<SearchCatalogUseCase>(),
      sl<GetSelectedCityUseCase>(),
    ),
  );
}
