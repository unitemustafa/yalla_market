import 'package:get_it/get_it.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../data/repositories/offer_remote_repository_impl.dart';
import '../data/repositories/offer_repository_impl.dart';
import '../domain/repositories/offer_repository.dart';
import '../domain/usecases/get_offers_usecase.dart';
import '../presentation/cubit/offer_catalog_cubit.dart';

void registerOfferDependencies(GetIt sl) {
  if (!sl.isRegistered<OfferRepository>()) {
    sl.registerLazySingleton<OfferRepository>(
      () => AppEnvironment.useDemoRepositories
          ? const OfferRepositoryImpl()
          : OfferRemoteRepositoryImpl(sl<ApiClient>()),
    );
  }
  if (!sl.isRegistered<GetOffersUseCase>()) {
    sl.registerLazySingleton(() => GetOffersUseCase(sl<OfferRepository>()));
  }
  if (!sl.isRegistered<OfferCatalogCubit>()) {
    sl.registerFactory(() => OfferCatalogCubit(sl<GetOffersUseCase>()));
  }
}
