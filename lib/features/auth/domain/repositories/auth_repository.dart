import 'dart:typed_data';

import '../../../../core/network/api_result.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';
import '../entities/otp_delivery_result.dart';

abstract class AuthRepository {
  Future<ApiResult<AuthSession?>> restoreSavedSession();

  Future<ApiResult<AuthSession>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  Future<ApiResult<bool>> isUsernameAvailable(String username);

  Future<ApiResult<bool>> isEmailRegistered(String email);

  Future<ApiResult<bool>> isPhoneRegistered(String phone);

  Future<ApiResult<AuthSession>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    required String phone,
  });

  Future<ApiResult<AuthSession>> verifyEmail({
    required String email,
    required String code,
  });

  Future<ApiResult<OtpDeliveryResult>> resendVerificationCode(String email);

  Future<ApiResult<OtpDeliveryResult>> requestPasswordReset(String email);

  Future<ApiResult<OtpDeliveryResult>> resendPasswordResetCode(String email);

  Future<ApiResult<bool>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirm,
  });

  Future<ApiResult<AuthUser>> me();

  Future<ApiResult<AuthUser>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? gender,
    DateTime? birthDate,
  });

  Future<ApiResult<AuthUser>> updateProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  });

  Future<ApiResult<bool>> logout();
}
