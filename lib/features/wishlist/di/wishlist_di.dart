import 'package:get_it/get_it.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../features/wishlist/data/repositories/wishlist_repository_impl.dart';
import '../../../features/wishlist/data/repositories/wishlist_remote_repository_impl.dart';
import '../../../features/wishlist/data/repositories/market_wishlist_remote_repository.dart';
import '../../../features/wishlist/domain/repositories/market_wishlist_repository.dart';
import '../../../features/wishlist/domain/repositories/wishlist_repository.dart';
import '../../../features/wishlist/domain/usecases/market_wishlist_usecases.dart';
import '../../../features/wishlist/domain/usecases/wishlist_usecases.dart';
import '../../../features/wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../../features/wishlist/presentation/cubit/market_wishlist_cubit.dart';

void registerWishlistDependencies(GetIt sl, {bool? useDemoRepositories}) {
  final useDemo = useDemoRepositories ?? AppEnvironment.useDemoRepositories;
  if (!sl.isRegistered<WishlistRepository>()) {
    sl.registerLazySingleton<WishlistRepository>(
      () => useDemo
          ? WishlistRepositoryImpl()
          : WishlistRemoteRepositoryImpl(sl<ApiClient>()),
    );
  }
  if (!sl.isRegistered<GetWishlistItemsUseCase>()) {
    sl.registerLazySingleton(
      () => GetWishlistItemsUseCase(sl<WishlistRepository>()),
    );
  }
  if (!sl.isRegistered<ToggleWishlistItemUseCase>()) {
    sl.registerLazySingleton(
      () => ToggleWishlistItemUseCase(sl<WishlistRepository>()),
    );
  }
  if (!sl.isRegistered<WishlistUseCases>()) {
    sl.registerLazySingleton(
      () => WishlistUseCases(
        getItems: sl<GetWishlistItemsUseCase>(),
        toggleItem: sl<ToggleWishlistItemUseCase>(),
      ),
    );
  }
  if (!sl.isRegistered<WishlistCubit>()) {
    sl.registerFactory(() => WishlistCubit(sl<WishlistUseCases>()));
  }
  if (!sl.isRegistered<MarketWishlistRepository>()) {
    sl.registerLazySingleton<MarketWishlistRepository>(
      () => MarketWishlistRemoteRepository(sl<ApiClient>()),
    );
  }
  if (!sl.isRegistered<MarketWishlistUseCases>()) {
    sl.registerLazySingleton(
      () => MarketWishlistUseCases(sl<MarketWishlistRepository>()),
    );
  }
  if (!sl.isRegistered<MarketWishlistCubit>()) {
    sl.registerFactory(() => MarketWishlistCubit(sl<MarketWishlistUseCases>()));
  }
}
