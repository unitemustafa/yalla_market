import 'dart:typed_data';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/otp_delivery_result.dart';
import '../../domain/entities/social_auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalAuthService _service = LocalAuthService();

  @override
  Future<ApiResult<AuthSession?>> restoreSavedSession() {
    return _guard(
      _service.restoreSavedSession,
      'Could not restore your session.',
    );
  }

  @override
  Future<ApiResult<AuthSession>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) {
    return _guard(
      () => _service.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      ),
      'Could not sign you in.',
    );
  }

  @override
  Future<ApiResult<SocialAuthResult>> socialSignIn({
    required SocialAuthProvider provider,
    bool rememberMe = false,
  }) async {
    return const ApiResult.failure(
      ValidationFailure('Social sign-in is unavailable in demo mode.'),
    );
  }

  @override
  Future<ApiResult<AuthSession>> completeSocialSignup({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String city,
    bool rememberMe = false,
  }) async {
    return const ApiResult.failure(
      ValidationFailure('Social sign-in is unavailable in demo mode.'),
    );
  }

  @override
  Future<ApiResult<AuthSession>> linkSocialAccount({
    required String password,
    bool rememberMe = false,
  }) async {
    return const ApiResult.failure(
      ValidationFailure('Social sign-in is unavailable in demo mode.'),
    );
  }

  @override
  Future<ApiResult<bool>> isUsernameAvailable(String username) {
    return _guard(
      () => _service.isUsernameAvailable(username),
      'Could not check this username.',
    );
  }

  @override
  Future<ApiResult<bool>> isEmailRegistered(String email) {
    return _guard(
      () => _service.isEmailRegistered(email),
      'Could not check this email.',
    );
  }

  @override
  Future<ApiResult<bool>> isPhoneRegistered(String phone) {
    return _guard(
      () => _service.isPhoneRegistered(phone),
      'Could not check this phone number.',
    );
  }

  @override
  Future<ApiResult<AuthSession>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    required String phone,
    required String city,
  }) {
    return _guard(
      () => _service.signup(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        username: username,
        phone: phone,
        city: city,
      ),
      'Could not create your account.',
    );
  }

  @override
  Future<ApiResult<AuthSession>> verifyEmail({
    required String email,
    required String code,
  }) {
    return _guard(
      () => _service.verifyEmail(email: email, code: code),
      'Could not verify your email.',
    );
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> resendVerificationCode(String email) {
    return _guard(
      () => _service.resendVerificationCode(email),
      'Could not send a new verification code.',
    );
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> requestPasswordReset(String email) {
    return _guard(
      () => _service.requestPasswordReset(email),
      'Could not send a password reset code.',
    );
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> resendPasswordResetCode(String email) {
    return _guard(
      () => _service.requestPasswordReset(email),
      'Could not send a password reset code.',
    );
  }

  @override
  Future<ApiResult<bool>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirm,
  }) {
    return _guard(
      () => _service.resetPassword(
        email: email,
        code: code,
        password: password,
        passwordConfirm: passwordConfirm,
      ),
      'Could not reset your password.',
    );
  }

  @override
  Future<ApiResult<AuthUser>> me() {
    return _guard(_service.me, 'Could not load your profile.');
  }

  @override
  Future<ApiResult<AuthUser>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? city,
    String? gender,
    DateTime? birthDate,
  }) {
    return _guard(
      () => _service.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        phone: phone,
        city: city,
        gender: gender,
        birthDate: birthDate,
      ),
      'Could not update your profile.',
    );
  }

  @override
  Future<ApiResult<AuthUser>> updateProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _guard(
      () => _service.updateProfileAvatar(bytes: bytes, fileName: fileName),
      'Could not update profile photo.',
    );
  }

  @override
  Future<ApiResult<bool>> logout() {
    return _guard(_service.logout, 'Could not sign you out.');
  }

  @override
  Future<ApiResult<bool>> deleteAccount({required String password}) {
    return _guard(
      () => _service.deleteAccount(password),
      'Could not delete your account.',
    );
  }

  Future<ApiResult<T>> _guard<T>(
    Future<T> Function() action,
    String fallbackMessage,
  ) async {
    try {
      return ApiResult.success(await action());
    } catch (error) {
      return ApiResult.failure(_failureFrom(error, fallbackMessage));
    }
  }

  Failure _failureFrom(Object error, String fallbackMessage) {
    if (error is Failure) return error;
    if (error is FormatException) {
      return ValidationFailure(error.message);
    }
    if (error is ArgumentError || error is StateError) {
      final message = error.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '');
      return ValidationFailure(message);
    }
    return UnknownFailure(fallbackMessage);
  }
}
