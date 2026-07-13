import 'dart:async';
import 'dart:typed_data';

import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_session.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_user.dart';
import 'package:yalla_market/features/auth/domain/entities/otp_delivery_result.dart';
import 'package:yalla_market/features/auth/domain/repositories/auth_repository.dart';
import 'package:yalla_market/features/auth/domain/usecases/auth_usecases.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/location/domain/repositories/location_repository.dart';
import 'package:yalla_market/features/location/domain/usecases/location_usecases.dart';

import 'domain_fixtures.dart';

AuthUseCases authUseCases(AuthRepository repository) {
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

LocationUseCases locationUseCases(LocationRepository repository) {
  final scopedRepository = repository as LocationUserScope;
  return LocationUseCases(
    activateUser: ActivateLocationUserUseCase(scopedRepository),
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

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.registeredEmails = const {},
    this.registeredPhones = const {},
    this.takenUsernames = const {},
    this.usernameCheckCompleters = const [],
    this.emailCheckCompleters = const [],
    this.phoneCheckCompleters = const [],
    this.usernameCheckFailure,
    this.emailCheckFailure,
    this.phoneCheckFailure,
    this.resendCompleter,
    this.resendFailure,
    this.passwordResetResults = const [],
    this.passwordResetCompleters = const [],
    this.passwordResetFailure,
    this.resetPasswordFailure,
  });

  final Set<String> registeredEmails;
  final Set<String> registeredPhones;
  final Set<String> takenUsernames;
  final List<Completer<ApiResult<bool>>> usernameCheckCompleters;
  final List<Completer<ApiResult<bool>>> emailCheckCompleters;
  final List<Completer<ApiResult<bool>>> phoneCheckCompleters;
  final Failure? usernameCheckFailure;
  final Failure? emailCheckFailure;
  final Failure? phoneCheckFailure;
  final Completer<ApiResult<OtpDeliveryResult>>? resendCompleter;
  final Failure? resendFailure;
  final List<OtpDeliveryResult> passwordResetResults;
  final List<Completer<ApiResult<OtpDeliveryResult>>> passwordResetCompleters;
  final Failure? passwordResetFailure;
  final Failure? resetPasswordFailure;
  int emailChecks = 0;
  int usernameChecks = 0;
  int phoneChecks = 0;
  int resendCalls = 0;
  int passwordResetRequests = 0;
  int resetPasswordCalls = 0;
  int loginCalls = 0;
  String? lastLoginEmail;
  bool? lastRememberMe;

  @override
  Future<ApiResult<AuthSession?>> restoreSavedSession() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<AuthSession>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    loginCalls += 1;
    lastLoginEmail = email;
    lastRememberMe = rememberMe;
    return ApiResult.success(sampleSession);
  }

  @override
  Future<ApiResult<bool>> isUsernameAvailable(String username) async {
    usernameChecks++;
    if (usernameCheckCompleters.isNotEmpty) {
      return usernameCheckCompleters.removeAt(0).future;
    }
    if (usernameCheckFailure != null) {
      return ApiResult.failure(usernameCheckFailure!);
    }
    return ApiResult.success(!takenUsernames.contains(username));
  }

  @override
  Future<ApiResult<bool>> isEmailRegistered(String email) async {
    emailChecks++;
    if (emailCheckCompleters.isNotEmpty) {
      return emailCheckCompleters.removeAt(0).future;
    }
    if (emailCheckFailure != null) {
      return ApiResult.failure(emailCheckFailure!);
    }
    return ApiResult.success(registeredEmails.contains(email));
  }

  @override
  Future<ApiResult<bool>> isPhoneRegistered(String phone) async {
    phoneChecks++;
    if (phoneCheckCompleters.isNotEmpty) {
      return phoneCheckCompleters.removeAt(0).future;
    }
    if (phoneCheckFailure != null) {
      return ApiResult.failure(phoneCheckFailure!);
    }
    return ApiResult.success(registeredPhones.contains(phone));
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
    return ApiResult.success(
      AuthSession(
        user: sampleUser.copyWith(
          email: email,
          firstName: firstName,
          lastName: lastName,
          username: username,
          phone: phone,
        ),
      ),
    );
  }

  @override
  Future<ApiResult<AuthSession>> verifyEmail({
    required String email,
    required String code,
  }) async {
    return ApiResult.success(sampleSession);
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> resendVerificationCode(
    String email,
  ) async {
    resendCalls++;
    if (resendCompleter != null) return resendCompleter!.future;
    if (resendFailure != null) return ApiResult.failure(resendFailure!);
    return const ApiResult.success(OtpDeliveryResult(resendAfterSeconds: 30));
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> requestPasswordReset(
    String email,
  ) async {
    passwordResetRequests++;
    if (passwordResetCompleters.isNotEmpty) {
      return passwordResetCompleters.removeAt(0).future;
    }
    if (passwordResetFailure != null) {
      return ApiResult.failure(passwordResetFailure!);
    }
    if (passwordResetResults.isNotEmpty) {
      final resultIndex = passwordResetRequests <= passwordResetResults.length
          ? passwordResetRequests - 1
          : passwordResetResults.length - 1;
      return ApiResult.success(passwordResetResults[resultIndex]);
    }
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
    resetPasswordCalls++;
    if (resetPasswordFailure != null) {
      return ApiResult.failure(resetPasswordFailure!);
    }
    return const ApiResult.success(true);
  }

  @override
  Future<ApiResult<AuthUser>> me() async {
    return ApiResult.success(sampleUser);
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
    return ApiResult.success(sampleUser);
  }

  @override
  Future<ApiResult<AuthUser>> updateProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    return ApiResult.success(sampleUser);
  }

  @override
  Future<ApiResult<bool>> logout() async {
    return const ApiResult.success(true);
  }
}

class FakeLocationRepository implements LocationRepository, LocationUserScope {
  int clearSelectedCityCalls = 0;

  @override
  Future<ApiResult<void>> activateUser(String userId) async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<List<CityData>>> getAvailableCities() async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<CityData?>> getSelectedCity() async {
    return const ApiResult.success(null);
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
    clearSelectedCityCalls++;
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
    return const ApiResult.success(CityData.general);
  }

  @override
  Future<ApiResult<CityData>> useCurrentLocation() async {
    return const ApiResult.success(CityData.general);
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
