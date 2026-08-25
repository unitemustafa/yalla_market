import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/home/domain/entities/home_data.dart';
import 'package:yalla_market/features/home/domain/repositories/home_repository.dart';
import 'package:yalla_market/features/home/domain/usecases/get_home_usecase.dart';
import 'package:yalla_market/features/home/presentation/cubit/home_cubit.dart';
import 'package:yalla_market/features/home/presentation/cubit/home_state.dart';

void main() {
  test('emits cached home then replaces it with network home', () async {
    final repository = _OfflineFirstHomeRepository();
    final cubit = HomeCubit(GetHomeUseCase(repository));
    addTearDown(cubit.close);
    final readyLocations = <String?>[];
    final subscription = cubit.stream.listen((state) {
      if (state case HomeReady(:final home)) {
        readyLocations.add(home.location?.name);
      }
    });
    addTearDown(subscription.cancel);

    await cubit.loadHome();
    await Future<void>.delayed(Duration.zero);

    expect(repository.forceRefreshValues, [false, true]);
    expect(readyLocations, ['cached', 'network']);
    expect((cubit.state as HomeReady).home.location?.name, 'network');
  });

  test('keeps cached home when silent network revalidation fails', () async {
    final cubit = HomeCubit(GetHomeUseCase(_FailingRevalidationRepository()));
    addTearDown(cubit.close);
    final states = <HomeState>[];
    final subscription = cubit.stream.listen(states.add);
    addTearDown(subscription.cancel);

    await cubit.loadHome();

    expect(cubit.state, isA<HomeReady>());
    expect(cubit.state.data?.location?.name, 'cached');
    expect(states.whereType<HomeFailure>(), isEmpty);
  });

  test('manual refresh failure retains the previously loaded home', () async {
    final repository = _ManualRefreshFailureRepository();
    final cubit = HomeCubit(GetHomeUseCase(repository));
    addTearDown(cubit.close);

    await cubit.loadHome();
    await cubit.loadHome(force: true);

    expect(cubit.state, isA<HomeFailure>());
    expect(cubit.state.data?.location?.name, 'network');
  });
}

class _OfflineFirstHomeRepository implements HomeRepository {
  final List<bool> forceRefreshValues = [];

  @override
  Future<ApiResult<HomeData>> getHome({bool forceRefresh = false}) async {
    forceRefreshValues.add(forceRefresh);
    final data = HomeData(
      location: HomeLocationData(
        addressId: '1',
        name: forceRefresh ? 'network' : 'cached',
        latitude: '0',
        longitude: '0',
      ),
      offers: const [],
      categories: const [],
      products: const [],
    );
    return ApiResult.success(
      data,
      origin: forceRefresh ? DataOrigin.network : DataOrigin.cache,
      savedAt: forceRefresh ? null : DateTime.utc(2030),
    );
  }
}

class _FailingRevalidationRepository implements HomeRepository {
  @override
  Future<ApiResult<HomeData>> getHome({bool forceRefresh = false}) async {
    if (forceRefresh) {
      return const ApiResult.failure(NetworkFailure('offline'));
    }
    return ApiResult.success(
      _homeNamed('cached'),
      origin: DataOrigin.cache,
      savedAt: DateTime.utc(2030),
    );
  }
}

class _ManualRefreshFailureRepository implements HomeRepository {
  @override
  Future<ApiResult<HomeData>> getHome({bool forceRefresh = false}) async {
    if (forceRefresh) {
      return const ApiResult.failure(NetworkFailure('offline'));
    }
    return ApiResult.success(_homeNamed('network'));
  }
}

HomeData _homeNamed(String name) {
  return HomeData(
    location: HomeLocationData(
      addressId: '1',
      name: name,
      latitude: '0',
      longitude: '0',
    ),
    offers: const [],
    categories: const [],
    products: const [],
  );
}
