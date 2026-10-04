import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/constants/app_colors.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_state.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';
import 'package:yalla_market/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:yalla_market/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:yalla_market/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:yalla_market/features/splash/presentation/cubit/splash_state.dart';
import 'package:yalla_market/features/splash/presentation/views/splash_view.dart';

import '../../../../helpers/auth_widget_fakes.dart';
import '../../../../helpers/domain_fixtures.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthGuard.clearAuthentication();
  });

  tearDown(AuthGuard.clearAuthentication);

  for (final size in const [
    Size(320, 568),
    Size(430, 932),
    Size(800, 1200),
    Size(800, 320),
  ]) {
    testWidgets('centers the visible badge on blue at $size', (tester) async {
      await _pumpSplash(tester, size: size, reduceMotion: true);
      final imageFinder = find.byKey(const ValueKey('splash_brand_logo'));
      final image = tester.widget<Image>(imageFinder);
      expect((image.image as AssetImage).assetName, AppAssets.splashBrandLogo);
      expect(image.fit, BoxFit.contain);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.splashBackground,
      );

      final imageSize = tester.getSize(imageFinder);
      final imageOrigin = tester.getTopLeft(imageFinder);
      // Measure the badge in the supplied canvas, rather than its transparent
      // margins. It must stay centered even on a short landscape viewport.
      final badgeCenter =
          imageOrigin +
          Offset(imageSize.width * 779.5 / 1536, imageSize.height * 464 / 1024);
      expect(badgeCenter.dx, closeTo(size.width / 2, 0.1));
      expect(badgeCenter.dy, closeTo(size.height / 2, 0.1));
      expect(imageSize.width, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('fast startup waits for entrance and exit before replacing', (
    tester,
  ) async {
    final harness = await _pumpSplash(
      tester,
      startupState: const SplashNavigateTo('/destination'),
    );
    expect(harness.splash.startupCalls, 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(harness.observer.replacements, isEmpty);
    // Advance past the final entrance tick, including its frame boundary.
    await tester.pump(const Duration(milliseconds: 510));
    expect(harness.observer.replacements, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.observer.replacements, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.observer.replacements, hasLength(1));
    await tester.pump();
    expect(find.text('destination'), findsOneWidget);
  });

  testWidgets('slow startup adds only the short exit after it becomes ready', (
    tester,
  ) async {
    final harness = await _pumpSplash(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(harness.observer.replacements, isEmpty);
    harness.splash.finish(const SplashNavigateTo('/destination'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(harness.observer.replacements, hasLength(1));
  });

  testWidgets('reduced motion skips the entrance and exit delays', (
    tester,
  ) async {
    final harness = await _pumpSplash(tester, reduceMotion: true);
    harness.splash.finish(const SplashNavigateTo('/destination'));
    await tester.pump();
    expect(harness.observer.replacements, hasLength(1));
    await tester.pump();
    expect(find.text('destination'), findsOneWidget);
  });

  testWidgets('enabling reduced motion during entrance releases navigation', (
    tester,
  ) async {
    final harness = await _pumpSplash(
      tester,
      startupState: const SplashNavigateTo('/destination'),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.observer.replacements, isEmpty);
    harness.motion.value = true;
    await tester.pump();
    await tester.pump();
    expect(harness.observer.replacements, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing during entrance cancels pending navigation safely', (
    tester,
  ) async {
    final harness = await _pumpSplash(
      tester,
      startupState: const SplashNavigateTo('/destination'),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(harness.observer.replacements, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing during exit does not navigate or leave a ticker', (
    tester,
  ) async {
    final harness = await _pumpSplash(tester);
    await tester.pump(const Duration(seconds: 1));
    harness.splash.finish(const SplashNavigateTo('/destination'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(harness.observer.replacements, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'restored session waits for user activation before syncing city',
    (tester) async {
      final activation = Completer<ApiResult<void>>();
      final repository = _DelayedLocationRepository(activation);
      final harness = await _pumpSplash(
        tester,
        reduceMotion: true,
        locationRepository: repository,
      );
      const city = CityData(name: 'Cairo', slug: 'cairo', serviceCityId: 1);
      harness.splash.finish(
        SplashNavigateTo('/destination', session: sampleSession, city: city),
      );
      await tester.pump();
      expect(harness.auth.state, isA<AuthAuthenticated>());
      expect(repository.activatedUserId, sampleSession.user.id);
      expect(harness.location.state.selectedCity, isNull);
      expect(harness.observer.replacements, isEmpty);
      activation.complete(const ApiResult.success(null));
      await tester.pump();
      expect(harness.location.state.selectedCity, city);
      expect(harness.observer.replacements, hasLength(1));
    },
  );
}

typedef _Harness = ({
  _ControlledSplashCubit splash,
  AuthCubit auth,
  LocationCubit location,
  _NavigationObserver observer,
  ValueNotifier<bool> motion,
});

Future<_Harness> _pumpSplash(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  bool reduceMotion = false,
  SplashNavigateTo? startupState,
  FakeLocationRepository? locationRepository,
}) async {
  await tester.binding.setSurfaceSize(size);
  final splash = _ControlledSplashCubit(startupState);
  final auth = AuthCubit(authUseCases(FakeAuthRepository()));
  final location = LocationCubit(
    locationUseCases(locationRepository ?? FakeLocationRepository()),
  );
  final observer = _NavigationObserver();
  final motion = ValueNotifier(reduceMotion);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await splash.close();
    await auth.close();
    await location.close();
    motion.dispose();
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<SplashCubit>.value(value: splash),
        BlocProvider<AuthCubit>.value(value: auth),
        BlocProvider<LocationCubit>.value(value: location),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        navigatorObservers: [observer],
        builder: (context, child) => ValueListenableBuilder<bool>(
          valueListenable: motion,
          builder: (context, reduced, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
        ),
        home: const SplashView(),
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => const Scaffold(body: Text('destination')),
        ),
      ),
    ),
  );
  // Decode the real bundled PNG outside the test's fake clock. The entrance
  // starts only after decoding; subsequent pumps control its time exactly.
  await tester.runAsync(
    () => precacheImage(
      const AssetImage(AppAssets.splashBrandLogo),
      tester.element(find.byType(SplashView)),
    ),
  );
  await tester.pump();
  return (
    splash: splash,
    auth: auth,
    location: location,
    observer: observer,
    motion: motion,
  );
}

class _ControlledSplashCubit extends SplashCubit {
  _ControlledSplashCubit(this._startupState)
    : super(
        OnboardingUseCases(
          hasSeenOnboarding: HasSeenOnboardingUseCase(_UnusedOnboarding()),
          markOnboardingSeen: MarkOnboardingSeenUseCase(_UnusedOnboarding()),
        ),
        authUseCases(FakeAuthRepository()),
        locationUseCases(FakeLocationRepository()),
      );

  final SplashNavigateTo? _startupState;
  int startupCalls = 0;

  @override
  Future<void> determineStartupRoute() async {
    startupCalls++;
    if (_startupState case final state?) emit(state);
  }

  void finish(SplashNavigateTo state) => emit(state);
}

class _UnusedOnboarding implements OnboardingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NavigationObserver extends NavigatorObserver {
  final replacements = <RouteSettings>[];

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) replacements.add(newRoute.settings);
  }
}

class _DelayedLocationRepository extends FakeLocationRepository {
  _DelayedLocationRepository(this.activation);

  final Completer<ApiResult<void>> activation;
  String? activatedUserId;

  @override
  Future<ApiResult<void>> activateUser(String userId) {
    activatedUserId = userId;
    return activation.future;
  }
}
