import 'package:get_it/get_it.dart';

import '../../core/di/core_di.dart';
import '../../features/auth/di/auth_di.dart';
import '../../features/app_media/data/remote_app_media_repository.dart';
import '../../features/app_media/domain/app_media_repository.dart';
import '../../features/app_media/domain/load_app_media.dart';
import '../../features/app_media/presentation/app_media_cubit.dart';
import '../../features/cart/di/cart_di.dart';
import '../../features/home/di/home_di.dart';
import '../../features/location/di/location_di.dart';
import '../../features/onboarding/di/onboarding_di.dart';
import '../../features/offers/di/offers_di.dart';
import '../../features/personalization/di/personalization_di.dart';
import '../../features/splash/di/splash_di.dart';
import '../../features/store/di/store_di.dart';
import '../../features/wishlist/di/wishlist_di.dart';

final GetIt sl = GetIt.instance;

void initServiceLocator() {
  registerCoreDependencies(sl);
  sl.registerLazySingleton<AppMediaRepository>(
    () => RemoteAppMediaRepository(createAppMediaDio()),
  );
  sl.registerLazySingleton(() => LoadAppMedia(sl<AppMediaRepository>()));
  sl.registerFactory(() => AppMediaCubit(sl<LoadAppMedia>()));
  registerOnboardingDependencies(sl);
  registerLocationDependencies(sl);
  registerAuthDependencies(sl);
  registerSplashDependencies(sl);
  registerHomeDependencies(sl);
  registerOfferDependencies(sl);
  registerStoreDependencies(sl);
  registerCartDependencies(sl);
  registerWishlistDependencies(sl);
  registerPersonalizationDependencies(sl);
}
