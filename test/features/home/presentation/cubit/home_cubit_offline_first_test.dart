import 'dart:async';

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

  test(
    'reloads a ready home only when its network data is 60 seconds old',
    () async {
      var now = DateTime.utc(2030, 1, 1, 12);
      final repository = _OfflineFirstHomeRepository();
      final cubit = HomeCubit(GetHomeUseCase(repository), now: () => now);
      addTearDown(cubit.close);

      await cubit.loadHome();
      expect(repository.forceRefreshValues, [false, true]);

      now = now.add(const Duration(seconds: 59));
      await cubit.loadHome();
      expect(repository.forceRefreshValues, [false, true]);

      now = now.add(const Duration(seconds: 1));
      await cubit.loadHome();
      expect(repository.forceRefreshValues, [false, true, true]);
    },
  );

  test('retries stale home revalidation after a silent failure', () async {
    var now = DateTime.utc(2030, 1, 1, 12);
    final repository = _RetryingHomeRepository();
    final cubit = HomeCubit(GetHomeUseCase(repository), now: () => now);
    addTearDown(cubit.close);

    await cubit.loadHome();
    now = now.add(const Duration(seconds: 60));
    await cubit.loadHome();
    await cubit.loadHome();

    expect(repository.forceRefreshValues, [false, true, true]);
    expect(cubit.state.data?.location?.name, 'network');
  });

  test('clearSession invalidates home freshness for the next load', () async {
    final repository = _OfflineFirstHomeRepository();
    final cubit = HomeCubit(GetHomeUseCase(repository));
    addTearDown(cubit.close);

    await cubit.loadHome();
    cubit.clearSession();
    await cubit.loadHome();

    expect(repository.forceRefreshValues, [false, true, false, true]);
  });

  test('an invalidated in-flight response does not make home fresh', () async {
    final repository = _BlockingHomeRepository();
    final cubit = HomeCubit(GetHomeUseCase(repository));
    addTearDown(cubit.close);

    await cubit.loadHome();
    final refresh = cubit.refreshSilently();
    await Future<void>.delayed(Duration.zero);
    cubit.invalidate();
    repository.networkResponses
        .removeAt(0)
        .complete(ApiResult.success(_homeNamed('stale network response')));
    await refresh;

    expect(cubit.lastNetworkSuccessAt, isNull);
    await cubit.refreshIfStale();
    expect(repository.forceRefreshValues, [false, true, true]);
  });

  test(
    'an old refresh waiter cannot reload after the session is cleared',
    () async {
      final repository = _BlockingHomeRepository();
      final cubit = HomeCubit(GetHomeUseCase(repository));
      addTearDown(cubit.close);
      await cubit.loadHome();
      final refresh = cubit.refreshSilently();
      cubit.invalidate();
      final waiter = cubit.refreshIfStale();
      cubit.clearSession();

      repository.networkResponses.single.complete(
        ApiResult.success(_homeNamed('old session')),
      );
      await Future.wait([refresh, waiter]);

      expect(cubit.state, isA<HomeInitial>());
      expect(repository.forceRefreshValues, [false, true]);
      expect(cubit.lastNetworkSuccessAt, isNull);
    },
  );
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

class _RetryingHomeRepository implements HomeRepository {
  final List<bool> forceRefreshValues = [];
  var _networkAttempts = 0;

  @override
  Future<ApiResult<HomeData>> getHome({bool forceRefresh = false}) async {
    forceRefreshValues.add(forceRefresh);
    if (!forceRefresh) return ApiResult.success(_homeNamed('network'));
    _networkAttempts++;
    if (_networkAttempts == 1) {
      return const ApiResult.failure(NetworkFailure('offline'));
    }
    return ApiResult.success(_homeNamed('network'));
  }
}

class _BlockingHomeRepository implements HomeRepository {
  final List<bool> forceRefreshValues = [];
  final List<Completer<ApiResult<HomeData>>> networkResponses = [];
  var _networkRequests = 0;

  @override
  Future<ApiResult<HomeData>> getHome({bool forceRefresh = false}) {
    forceRefreshValues.add(forceRefresh);
    if (!forceRefresh) {
      return Future.value(ApiResult.success(_homeNamed('home')));
    }
    _networkRequests++;
    final completer = Completer<ApiResult<HomeData>>();
    networkResponses.add(completer);
    if (_networkRequests > 1) {
      completer.complete(
        ApiResult.success(_homeNamed('fresh network response')),
      );
    }
    return completer.future;
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
