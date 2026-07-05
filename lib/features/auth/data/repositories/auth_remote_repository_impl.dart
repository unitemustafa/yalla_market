import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/token_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/otp_delivery_result.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRemoteRepositoryImpl implements AuthRepository {
  AuthRemoteRepositoryImpl(this._apiClient, this._tokenStore);

  static const _legacySessionKey = 'auth.local_session';
  static const _legacyAccountsKey = 'auth.local_accounts';
  static const _sessionOnlyActiveKey = 'auth.session_only_active';
  static const _rememberedSessionDuration = Duration(days: 30);
  static const _temporarySessionDuration = Duration(hours: 8);
  static Options get _skipAuthOptions =>
      Options(extra: const {'skipAuth': true});

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  @override
  Future<ApiResult<AuthSession?>> restoreSavedSession() {
    return _guard(() async {
      await _clearLegacyLocalAuth();
      final tokens = await _tokenStore.read();
      if (tokens == null) {
        if (await _consumeSessionOnlyActiveMarker()) {
          throw const UnauthorizedFailure('Session expired.');
        }
        return null;
      }
      if (tokens.isExpired) {
        await _tokenStore.clear();
        await _clearSessionOnlyActiveMarker();
        throw const UnauthorizedFailure('Session expired.');
      }

      final user = await _loadMe();
      return AuthSession(
        user: user,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: tokens.expiresAt,
      );
    });
  }

  @override
  Future<ApiResult<AuthSession>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) {
    return _guard(() async {
      final identifier = _normalizeLoginIdentifier(email);
      final payload = await _apiClient.post<Map<String, dynamic>>(
        '/auth/login/client',
        data: {'identifier': identifier, 'password': password},
        options: _skipAuthOptions,
      );
      return _sessionFromPayload(payload, persistTokens: rememberMe);
    });
  }

  @override
  Future<ApiResult<bool>> isUsernameAvailable(String username) {
    return _guard(() async {
      final payload = await _apiClient.get<Map<String, dynamic>>(
        '/auth/check-username',
        queryParameters: {'username': username},
        options: _skipAuthOptions,
      );
      return _availabilityFromPayload(payload);
    });
  }

  @override
  Future<ApiResult<bool>> isEmailRegistered(String email) {
    return _guard(() async {
      final payload = await _apiClient.get<Map<String, dynamic>>(
        '/auth/check-email',
        queryParameters: {'email': email},
        options: _skipAuthOptions,
      );
      return _registrationFromPayload(payload);
    });
  }

  @override
  Future<ApiResult<bool>> isPhoneRegistered(String phone) {
    return _guard(() async {
      final payload = await _apiClient.get<Map<String, dynamic>>(
        '/auth/check-phone',
        queryParameters: {'phone': phone},
        options: _skipAuthOptions,
      );
      return _registrationFromPayload(payload);
    });
  }

  @override
  Future<ApiResult<AuthSession>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    required String phone,
  }) {
    return _guard(() async {
      await _tokenStore.clear();
      final payload = await _apiClient.post<Map<String, dynamic>>(
        '/auth/signup',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'password_confirm': password,
          'terms_accepted': true,
          'username': username,
          'phone': phone,
        },
        options: _skipAuthOptions,
      );
      return _signupSessionFromPayload(
        payload,
        firstName: firstName,
        lastName: lastName,
        email: email,
        username: username,
        phone: phone,
      );
    });
  }

  @override
  Future<ApiResult<AuthUser>> me() {
    return _guard(_loadMe);
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
  }) {
    return _guard(() {
      return _apiClient
          .patch<Map<String, dynamic>>(
            '/auth/client/profile/',
            data: {
              'first_name': ?firstName,
              'last_name': ?lastName,
              'username': ?username,
              'email': ?email,
              'phone': ?phone,
              'gender': ?gender,
              'birth_date': ?_dateOnly(birthDate),
            },
          )
          .then(_userFromPayload);
    });
  }

  @override
  Future<ApiResult<AuthUser>> updateProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _guard(() {
      final formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      return _apiClient
          .patch<Map<String, dynamic>>('/auth/client/profile/', data: formData)
          .then(_userFromPayload);
    });
  }

  @override
  Future<ApiResult<bool>> logout() {
    return _guard(() async {
      try {
        final tokens = await _tokenStore.read();
        if (tokens != null) {
          await _apiClient.post<Object?>(
            '/auth/logout',
            data: {'refreshToken': tokens.refreshToken},
          );
        }
      } finally {
        await _tokenStore.clear();
        await _clearSessionOnlyActiveMarker();
      }
      return true;
    });
  }

  @override
  Future<ApiResult<bool>> deleteAccountWithPassword(String password) {
    return _guard(() async {
      await _apiClient.delete<Object?>(
        '/auth/me',
        data: {'password': password},
      );
      await _tokenStore.clear();
      await _clearSessionOnlyActiveMarker();
      return true;
    });
  }

  Future<AuthUser> _loadMe() async {
    final payload = await _apiClient.get<Map<String, dynamic>>('/auth/me');
    return _userFromPayload(payload);
  }

  Future<AuthSession> _sessionFromPayload(
    Map<String, dynamic> payload, {
    required bool persistTokens,
  }) async {
    final user = _userFromPayload(payload);
    final tokensPayload = _asJsonMap(payload['tokens']) ?? payload;
    final sessionExpiresAt = DateTime.now().add(
      persistTokens ? _rememberedSessionDuration : _temporarySessionDuration,
    );
    final tokens = tokensFromApiPayload(
      tokensPayload,
    ).copyWith(expiresAt: sessionExpiresAt, isSessionOnly: !persistTokens);
    await _tokenStore.save(tokens);
    if (persistTokens) {
      await _clearSessionOnlyActiveMarker();
    } else {
      await _markSessionOnlyActive();
    }
    return AuthSession(
      user: user,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
    );
  }

  Future<AuthSession> _signupSessionFromPayload(
    Map<String, dynamic> payload, {
    required String firstName,
    required String lastName,
    required String email,
    String? username,
    String? phone,
  }) async {
    final user = _signupUserFromPayload(
      payload,
      firstName: firstName,
      lastName: lastName,
      email: email,
      username: username,
      phone: phone,
    );
    final tokens = _optionalTokensFromPayload(payload);
    if (tokens != null) {
      await _tokenStore.save(tokens.copyWith(isSessionOnly: true));
      await _markSessionOnlyActive();
    } else {
      await _clearSessionOnlyActiveMarker();
    }

    return AuthSession(
      user: user,
      accessToken: tokens?.accessToken,
      refreshToken: tokens?.refreshToken,
      expiresAt: tokens?.expiresAt,
      otpResendAfterSeconds: _intFromPayload(payload, 'resend_after_seconds'),
    );
  }

  @override
  Future<ApiResult<AuthSession>> verifyEmail({
    required String email,
    required String code,
  }) {
    return _guard(() async {
      final payload = await _apiClient.post<Map<String, dynamic>>(
        '/auth/verify-email',
        data: {'email': email, 'otp': code},
        options: _skipAuthOptions,
      );
      return _sessionFromPayload(payload, persistTokens: false);
    });
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> resendVerificationCode(String email) {
    return _guard(() async {
      final payload = await _apiClient.post<Object?>(
        '/auth/resend-verification',
        data: {'email': email},
        options: _skipAuthOptions,
      );
      return _otpDeliveryResult(payload);
    });
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> requestPasswordReset(String email) {
    return _guard(() async {
      final payload = await _apiClient.post<Object?>(
        '/auth/forgot-password',
        data: {'email': email},
        options: _skipAuthOptions,
      );
      return _otpDeliveryResult(payload);
    });
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> resendPasswordResetCode(String email) {
    return requestPasswordReset(email);
  }

  @override
  Future<ApiResult<bool>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirm,
  }) {
    return _guard(() async {
      await _apiClient.post<Object?>(
        '/auth/reset-password',
        data: {
          'email': email,
          'otp': code,
          'password': password,
          'password_confirm': passwordConfirm,
        },
        options: _skipAuthOptions,
      );
      await _tokenStore.clear();
      await _clearSessionOnlyActiveMarker();
      return true;
    });
  }

  AuthUser _signupUserFromPayload(
    Map<String, dynamic> payload, {
    required String firstName,
    required String lastName,
    required String email,
    String? username,
    String? phone,
  }) {
    final rawUser = _asJsonMap(payload['user']);
    if (rawUser != null) return AuthUser.fromJson(rawUser);

    final fallbackEmail = _stringFromPayload(payload, 'email') ?? email;
    final normalizedEmail = fallbackEmail.trim().toLowerCase();
    return AuthUser(
      id:
          _stringFromPayload(payload, 'id') ??
          _signupFallbackId(normalizedEmail),
      email: normalizedEmail,
      firstName:
          _stringFromPayload(payload, 'firstName') ??
          _stringFromPayload(payload, 'first_name') ??
          firstName.trim(),
      lastName:
          _stringFromPayload(payload, 'lastName') ??
          _stringFromPayload(payload, 'last_name') ??
          lastName.trim(),
      role: _stringFromPayload(payload, 'role') ?? 'CUSTOMER',
      username: _stringFromPayload(payload, 'username') ?? username?.trim(),
      phone: _stringFromPayload(payload, 'phone') ?? phone?.trim(),
    );
  }

  OtpDeliveryResult _otpDeliveryResult(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final seconds = _intFromPayload(payload, 'resend_after_seconds');
      return OtpDeliveryResult(
        resendAfterSeconds: seconds,
        resendAvailableAt: _dateFromString(payload['resend_available_at']),
      );
    }
    return const OtpDeliveryResult();
  }

  AuthUser _userFromPayload(Map<String, dynamic> payload) {
    final rawUser = payload['user'] ?? payload;
    return AuthUser.fromJson(_asJsonMap(rawUser) ?? const <String, dynamic>{});
  }

  StoredAuthTokens? _optionalTokensFromPayload(Map<String, dynamic> payload) {
    final tokensPayload = _asJsonMap(payload['tokens']) ?? payload;
    final hasAccessToken =
        tokensPayload['accessToken'] != null ||
        tokensPayload['access_token'] != null;
    final hasRefreshToken =
        tokensPayload['refreshToken'] != null ||
        tokensPayload['refresh_token'] != null;

    if (!hasAccessToken || !hasRefreshToken) return null;

    try {
      return tokensFromApiPayload(tokensPayload);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? _stringFromPayload(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  int? _intFromPayload(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _dateFromString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _signupFallbackId(String email) {
    final normalized = email
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'pending-${normalized.isEmpty ? 'user' : normalized}';
  }

  String _normalizeLoginIdentifier(String value) {
    final trimmed = value.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return trimmed;

    if (digits.startsWith('0')) return '+20${digits.substring(1)}';
    if (digits.startsWith('20')) return '+$digits';
    if (digits.length == 10 && digits.startsWith('1')) return '+20$digits';
    return trimmed;
  }

  String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  bool _availabilityFromPayload(Map<String, dynamic> payload) {
    final value = payload['available'] ?? payload['isAvailable'];
    if (value is bool) return value;
    final registered = payload['registered'] ?? payload['isRegistered'];
    if (registered is bool) return !registered;
    return false;
  }

  bool _registrationFromPayload(Map<String, dynamic> payload) {
    final value = payload['registered'] ?? payload['isRegistered'];
    if (value is bool) return value;
    final available = payload['available'] ?? payload['isAvailable'];
    if (available is bool) return !available;
    return false;
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } on Failure catch (failure) {
      return ApiResult.failure(failure);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not complete the request.'),
      );
    }
  }

  Future<void> _clearLegacyLocalAuth() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_legacySessionKey);
    await preferences.remove(_legacyAccountsKey);
  }

  Future<void> _markSessionOnlyActive() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_sessionOnlyActiveKey, true);
  }

  Future<void> _clearSessionOnlyActiveMarker() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionOnlyActiveKey);
  }

  Future<bool> _consumeSessionOnlyActiveMarker() async {
    final preferences = await SharedPreferences.getInstance();
    final wasSessionOnly = preferences.getBool(_sessionOnlyActiveKey) ?? false;
    if (wasSessionOnly) {
      await preferences.remove(_sessionOnlyActiveKey);
    }
    return wasSessionOnly;
  }
}
