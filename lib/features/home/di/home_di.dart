import 'package:get_it/get_it.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../data/repositories/home_remote_repository_impl.dart';
import '../data/repositories/home_repository_impl.dart';
import '../data/repositories/notification_remote_repository_impl.dart';
import '../domain/repositories/home_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/usecases/get_home_usecase.dart';
import '../presentation/cubit/home_cubit.dart';
import '../presentation/cubit/notification_cubit.dart';

void registerHomeDependencies(GetIt sl) {
  if (!sl.isRegistered<HomeRepository>()) {
    sl.registerLazySingleton<HomeRepository>(
      () => AppEnvironment.useDemoRepositories
          ? HomeRepositoryImpl()
          : HomeRemoteRepositoryImpl(sl<ApiClient>()),
    );
  }
  if (!sl.isRegistered<NotificationRepository>()) {
    sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRemoteRepositoryImpl(sl<ApiClient>()),
    );
  }
  if (!sl.isRegistered<GetHomeUseCase>()) {
    sl.registerLazySingleton(() => GetHomeUseCase(sl<HomeRepository>()));
  }
  if (!sl.isRegistered<HomeCubit>()) {
    sl.registerFactory(() => HomeCubit(sl<GetHomeUseCase>()));
  }
  if (!sl.isRegistered<NotificationCubit>()) {
    sl.registerFactory(() => NotificationCubit(sl<NotificationRepository>()));
  }
}
