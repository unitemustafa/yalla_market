import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_session.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_user.dart';
import 'package:yalla_market/features/auth/domain/entities/otp_delivery_result.dart';
import 'package:yalla_market/features/auth/domain/repositories/auth_repository.dart';
import 'package:yalla_market/features/auth/domain/usecases/auth_usecases.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/location/domain/repositories/location_repository.dart';
import 'package:yalla_market/features/location/domain/usecases/location_usecases.dart';
import 'package:yalla_market/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:yalla_market/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:yalla_market/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:yalla_market/features/splash/presentation/cubit/splash_state.dart';

import '../../../../helpers/domain_fixtures.dart';

void main() {
  group('SplashCubit', () {
    test(
      'onboarding not seen routes to onboarding and does not restore session',
      () async {
        final authRepository = _FakeAuthRepository();
        final cubit = _cubit(
          onboardingRepository: const _FakeOnboardingRepository(seen: false),
          authRepository: authRepository,
        );

        await cubit.determineStartupRoute();

        final state = cubit.state as SplashNavigateTo;
        expect(state.route, AppRoutes.onboarding);
        expect(authRepository.restoreSavedSessionCalls, 0);
        await cubit.close();
      },
    );

    test('onboarding seen with no session routes to login', () async {
      final cubit = _cubit(
        onboardingRepository: const _FakeOnboardingRepository(seen: true),
        authRepository: _FakeAuthRepository(),
      );

      await cubit.determineStartupRoute();

      final state = cubit.state as SplashNavigateTo;
      expect(state.route, AppRoutes.login);
      expect(state.sessionExpired, isFalse);
      await cubit.close();
    });

    test(
      'expired unauthorized saved session routes to login with sessionExpired',
      () async {
        final cubit = _cubit(
          onboardingRepository: const _FakeOnboardingRepository(seen: true),
          authRepository: _FakeAuthRepository(
            restoreFailure: const UnauthorizedFailure('Session expired.'),
          ),
        );

        await cubit.determineStartupRoute();

        final state = cubit.state as SplashNavigateTo;
        expect(state.route, AppRoutes.login);
        expect(state.sessionExpired, isTrue);
        await cubit.close();
      },
    );

    test('valid session with no saved city routes to selectCity', () async {
      final cubit = _cubit(
        onboardingRepository: const _FakeOnboardingRepository(seen: true),
        authRepository: _FakeAuthRepository(session: sampleSession),
        locationRepository: _FakeLocationRepository(),
      );

      await cubit.determineStartupRoute();

      final state = cubit.state as SplashNavigateTo;
      expect(state.route, AppRoutes.selectCity);
      expect(state.session, same(sampleSession));
      expect(state.city, isNull);
      await cubit.close();
    });

    test('valid session with saved city routes to navigationMenu', () async {
      const city = CityData(name: 'Cairo', slug: 'cairo', serviceCityId: 1);
      final cubit = _cubit(
        onboardingRepository: const _FakeOnboardingRepository(seen: true),
        authRepository: _FakeAuthRepository(session: sampleSession),
        locationRepository: _FakeLocationRepository(city: city),
      );

      await cubit.determineStartupRoute();

      final state = cubit.state as SplashNavigateTo;
      expect(state.route, AppRoutes.navigationMenu);
      expect(state.session, same(sampleSession));
      expect(state.city, city);
      await cubit.close();
    });

    test(
      'valid session activates user with user id before reading selected city',
      () async {
        final events = <String>[];
        final locationRepository = _FakeLocationRepository(events: events);
        final cubit = _cubit(
          onboardingRepository: const _FakeOnboardingRepository(seen: true),
          authRepository: _FakeAuthRepository(session: sampleSession),
          locationRepository: locationRepository,
        );

        await cubit.determineStartupRoute();

        expect(events, ['activateUser:${sampleUser.id}', 'getSelectedCity']);
        await cubit.close();
      },
    );
  });
}

SplashCubit _cubit({
  required OnboardingRepository onboardingRepository,
  AuthRepository? authRepository,
  LocationRepository? locationRepository,
}) {
  final effectiveLocationRepository =
      locationRepository ?? _FakeLocationRepository();
  return SplashCubit(
    _onboardingUseCases(onboardingRepository),
    _authUseCases(authRepository ?? _FakeAuthRepository()),
    _locationUseCases(effectiveLocationRepository),
  );
}

OnboardingUseCases _onboardingUseCases(OnboardingRepository repository) {
  return OnboardingUseCases(
    hasSeenOnboarding: HasSeenOnboardingUseCase(repository),
    markOnboardingSeen: MarkOnboardingSeenUseCase(repository),
  );
}

AuthUseCases _authUseCases(AuthRepository repository) {
  return AuthUseCases(
    restoreSavedSession: RestoreSavedSessionUseCase(repository),
    login: LoginUseCase(repository),
    checkUsernameAvailability: CheckUsernameAvailabilityUseCase(repository),
    checkEmailRegistration: CheckEmailRegistrationUseCase(repository),
    checkPhoneRegistration: CheckPhoneRegistrationUseCase(repository),
    signup: SignupUseCase(repository),
    verifyEmail: VerifyEmailUseCase(repository),
    resendVerificationCode: ResendVerificationCodeUseCase(repository),
    requestPasswordReset: RequestPasswordResetUseCase(repository),
    resendPasswordResetCode: ResendPasswordResetCodeUseCase(repository),
    resetPassword: ResetPasswordUseCase(repository),
    refreshProfile: RefreshProfileUseCase(repository),
    updateProfile: UpdateProfileUseCase(repository),
    updateProfileAvatar: UpdateProfileAvatarUseCase(repository),
    logout: LogoutUseCase(repository),
  );
}

LocationUseCases _locationUseCases(LocationRepository repository) {
  return LocationUseCases(
    activateUser: ActivateLocationUserUseCase(repository as LocationUserScope),
    getAvailableCities: GetAvailableCitiesUseCase(repository),
    getSelectedCity: GetSelectedCityUseCase(repository),
    hasSeenCitySelection: HasSeenCitySelectionUseCase(repository),
    markCitySelectionSeen: MarkCitySelectionSeenUseCase(repository),
    clearSelectedCity: ClearSelectedCityUseCase(repository),
    saveSelectedCity: SaveSelectedCityUseCase(repository),
    detectCurrentLocation: DetectCurrentLocationUseCase(repository),
    useCurrentLocation: UseCurrentLocationUseCase(repository),
    openAppSettings: OpenLocationAppSettingsUseCase(repository),
    openLocationSettings: OpenDeviceLocationSettingsUseCase(repository),
  );
}

class _FakeOnboardingRepository implements OnboardingRepository {
  const _FakeOnboardingRepository({required this.seen});

  final bool seen;

  @override
  Future<ApiResult<bool>> hasSeenOnboarding() async {
    return ApiResult.success(seen);
  }

  @override
  Future<ApiResult<bool>> markOnboardingSeen() async {
    return const ApiResult.success(true);
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.session, this.restoreFailure});

  final AuthSession? session;
  final Failure? restoreFailure;
  int restoreSavedSessionCalls = 0;

  @override
  Future<ApiResult<AuthSession?>> restoreSavedSession() async {
    restoreSavedSessionCalls += 1;
    if (restoreFailure case final failure?) {
      return ApiResult.failure(failure);
    }
    return ApiResult.success(session);
  }

  @override
  Future<ApiResult<AuthSession>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    return ApiResult.success(session ?? sampleSession);
  }

  @override
  Future<ApiResult<bool>> isUsernameAvailable(String username) async {
    return const ApiResult.success(true);
  }

  @override
  Future<ApiResult<bool>> isEmailRegistered(String email) async {
    return const ApiResult.success(false);
  }

  @override
  Future<ApiResult<bool>> isPhoneRegistered(String phone) async {
    return const ApiResult.success(false);
  }

  @override
  Future<ApiResult<AuthSession>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    required String phone,
  }) async {
    return ApiResult.success(session ?? sampleSession);
  }

  @override
  Future<ApiResult<AuthSession>> verifyEmail({
    required String email,
    required String code,
  }) async {
    return ApiResult.success(session ?? sampleSession);
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> resendVerificationCode(
    String email,
  ) async {
    return const ApiResult.success(OtpDeliveryResult(resendAfterSeconds: 30));
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> requestPasswordReset(
    String email,
  ) async {
    return const ApiResult.success(OtpDeliveryResult(resendAfterSeconds: 30));
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> resendPasswordResetCode(
    String email,
  ) async {
    return const ApiResult.success(OtpDeliveryResult(resendAfterSeconds: 30));
  }

  @override
  Future<ApiResult<bool>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirm,
  }) async {
    return const ApiResult.success(true);
  }

  @override
  Future<ApiResult<AuthUser>> me() async {
    return const ApiResult.success(sampleUser);
  }

  @override
  Future<ApiResult<AuthUser>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? gender,
    DateTime? birthDate,
  }) async {
    return const ApiResult.success(sampleUser);
  }

  @override
  Future<ApiResult<AuthUser>> updateProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    return const ApiResult.success(sampleUser);
  }

  @override
  Future<ApiResult<bool>> logout() async {
    return const ApiResult.success(true);
  }
}

class _FakeLocationRepository implements LocationRepository, LocationUserScope {
  _FakeLocationRepository({this.city, List<String>? events})
    : events = events ?? <String>[];

  final CityData? city;
  final List<String> events;

  @override
  Future<ApiResult<void>> activateUser(String userId) async {
    events.add('activateUser:$userId');
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<CityData?>> getSelectedCity() async {
    events.add('getSelectedCity');
    return ApiResult.success(city);
  }

  @override
  Future<ApiResult<List<CityData>>> getAvailableCities() async {
    return const ApiResult.success([
      CityData(name: 'Cairo', slug: 'cairo', serviceCityId: 1),
    ]);
  }

  @override
  Future<ApiResult<bool>> hasSeenCitySelection() async {
    return const ApiResult.success(false);
  }

  @override
  Future<ApiResult<void>> markCitySelectionSeen() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> clearSelectedCity() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<CityData>> saveSelectedCity(CityData city) async {
    return ApiResult.success(city);
  }

  @override
  Future<ApiResult<CityData>> detectCurrentLocation({
    bool requestPermission = true,
  }) async {
    return const ApiResult.success(
      CityData(name: 'Cairo', slug: 'cairo', serviceCityId: 1),
    );
  }

  @override
  Future<ApiResult<CityData>> useCurrentLocation() async {
    return const ApiResult.success(
      CityData(name: 'Cairo', slug: 'cairo', serviceCityId: 1),
    );
  }

  @override
  Future<ApiResult<void>> openAppSettings() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> openLocationSettings() async {
    return const ApiResult.success(null);
  }
}
