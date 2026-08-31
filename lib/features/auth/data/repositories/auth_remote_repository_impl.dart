import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/session/session_deadline_controller.dart';
import '../../../../core/session/session_metadata.dart';
import '../../../../core/storage/token_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/otp_delivery_result.dart';
import '../../domain/entities/social_auth_result.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRemoteRepositoryImpl implements AuthRepository {
  AuthRemoteRepositoryImpl(
    this._apiClient,
    this._tokenStore, {
    SessionDeadlineController? sessionDeadlineController,
  }) : _sessionDeadlineController =
           sessionDeadlineController ??
           SessionDeadlineController(tokenStore: _tokenStore);

  static const _legacySessionKey = 'auth.local_session';
  static const _legacyAccountsKey = 'auth.local_accounts';
  static const _cachedUserKey = 'auth.cached_user.v1';
  static Options get _skipAuthOptions =>
      Options(extra: const {'skipAuth': true});

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  final SessionDeadlineController _sessionDeadlineController;
  String? _pendingSocialIdToken;
  SocialAuthProvider? _pendingSocialProvider;
  Future<void>? _googleInitialization;

  @override
  Future<ApiResult<AuthSession?>> restoreSavedSession() {
    return _guard(() async {
      await _clearLegacyLocalAuth();
      final restoredTokens = await _tokenStore.read();
      if (restoredTokens == null) return null;
      if (!await _sessionDeadlineController.activate(restoredTokens)) {
        throw const UnauthorizedFailure('Session expired.');
      }

      late final AuthUser user;
      try {
        user = await _loadMe();
      } on DioException catch (error) {
        if (!_canRestoreOffline(error)) rethrow;
        final cachedUser = await _readCachedUser();
        if (cachedUser == null) rethrow;
        user = cachedUser;
      }
      final currentTokens = await _tokenStore.read();
      if (currentTokens == null ||
          !await _sessionDeadlineController.activate(currentTokens)) {
        throw const UnauthorizedFailure('Session expired.');
      }
      return _authSession(user, currentTokens);
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
        ApiEndpoints.clientLogin,
        data: {
          'identifier': identifier,
          'password': password,
          'remember': rememberMe,
        },
        options: _skipAuthOptions,
      );
      return _sessionFromPayload(payload);
    });
  }

  @override
  Future<ApiResult<SocialAuthResult>> socialSignIn({
    required SocialAuthProvider provider,
    bool rememberMe = false,
  }) {
    return _guard(() async {
      await _sessionDeadlineController.clearSession();
      final idToken = await _firebaseIdToken(provider);
      _pendingSocialIdToken = idToken;
      _pendingSocialProvider = provider;
      final payload = await _apiClient.post<Map<String, dynamic>>(
        '/auth/social/session',
        data: {'id_token': idToken, 'remember': rememberMe},
        options: _skipAuthOptions,
      );
      final status = payload['status']?.toString();
      if (status == 'authenticated') {
        final session = await _sessionFromPayload(payload);
        _clearPendingSocialAuth();
        return SocialAuthResult(
          action: SocialAuthAction.authenticated,
          provider: provider,
          email: session.user.email,
          session: session,
        );
      }
      final email = payload['email']?.toString().trim() ?? '';
      if (status == 'account_link_required') {
        return SocialAuthResult(
          action: SocialAuthAction.linkAccount,
          provider: provider,
          email: email,
        );
      }
      if (status != 'profile_completion_required' || email.isEmpty) {
        throw const ValidationFailure('Invalid social sign-in response.');
      }
      return SocialAuthResult(
        action: SocialAuthAction.completeProfile,
        provider: provider,
        email: email,
        firstName: payload['first_name']?.toString() ?? '',
        lastName: payload['last_name']?.toString() ?? '',
        avatarUrl: payload['avatar_url']?.toString(),
        emailVerified: payload['email_verified'] == true,
      );
    });
  }

  @override
  Future<ApiResult<AuthSession>> completeSocialSignup({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String city,
    bool rememberMe = false,
  }) {
    return _guard(() async {
      final idToken = _requirePendingSocialToken();
      final payload = await _apiClient.post<Map<String, dynamic>>(
        '/auth/social/signup',
        data: {
          'id_token': idToken,
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'phone': phone,
          'city': city,
          'terms_accepted': true,
          'remember': rememberMe,
        },
        options: _skipAuthOptions,
      );
      final session = await _signupSessionFromPayload(
        payload,
        firstName: firstName,
        lastName: lastName,
        email: payload['email']?.toString() ?? '',
        username: username,
        phone: phone,
        city: city,
      );
      _clearPendingSocialAuth();
      return session;
    });
  }

  @override
  Future<ApiResult<AuthSession>> linkSocialAccount({
    required String password,
    bool rememberMe = false,
  }) {
    return _guard(() async {
      final idToken = _requirePendingSocialToken();
      final payload = await _apiClient.post<Map<String, dynamic>>(
        '/auth/social/link',
        data: {
          'id_token': idToken,
          'password': password,
          'remember': rememberMe,
        },
        options: _skipAuthOptions,
      );
      final session = await _sessionFromPayload(payload);
      _clearPendingSocialAuth();
      return session;
    });
  }

  Future<String> _firebaseIdToken(SocialAuthProvider provider) async {
    if (Firebase.apps.isEmpty) {
      throw const ValidationFailure(
        'Social sign-in is not configured on this device.',
      );
    }
    try {
      final credential = switch (provider) {
        SocialAuthProvider.google => await _signInWithGoogle(),
        SocialAuthProvider.facebook => await _signInWithFacebook(),
        SocialAuthProvider.apple => await _signInWithApple(),
      };
      final token = await credential.user?.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw const ValidationFailure('Social sign-in did not return a token.');
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const ValidationFailure('Google sign-in was cancelled.');
      }
      throw const ValidationFailure('Google sign-in could not be completed.');
    } on firebase_auth.FirebaseAuthException catch (error) {
      final message = switch (error.code) {
        'account-exists-with-different-credential' =>
          'An account already exists with a different sign-in method.',
        'user-disabled' => 'This social account is disabled.',
        _ => 'Social sign-in could not be completed.',
      };
      throw ValidationFailure(message);
    }
  }

  Future<firebase_auth.UserCredential> _signInWithGoogle() async {
    final credential = await _googleCredential();
    return firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<firebase_auth.OAuthCredential> _googleCredential() async {
    _googleInitialization ??= GoogleSignIn.instance.initialize();
    await _googleInitialization;
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleIdToken = googleUser.authentication.idToken;
    if (googleIdToken == null || googleIdToken.isEmpty) {
      throw const ValidationFailure('Google did not return an identity token.');
    }
    return firebase_auth.GoogleAuthProvider.credential(idToken: googleIdToken);
  }

  Future<firebase_auth.UserCredential> _signInWithFacebook() async {
    final credential = await _facebookCredential();
    return firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<firebase_auth.OAuthCredential> _facebookCredential() async {
    final result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );
    if (result.status != LoginStatus.success || result.accessToken == null) {
      final message = result.status == LoginStatus.cancelled
          ? 'Facebook sign-in was cancelled.'
          : 'Facebook sign-in could not be completed.';
      throw ValidationFailure(message);
    }
    return firebase_auth.FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );
  }

  Future<firebase_auth.UserCredential> _signInWithApple() {
    return firebase_auth.FirebaseAuth.instance.signInWithProvider(
      _appleProvider(),
    );
  }

  firebase_auth.AppleAuthProvider _appleProvider() {
    return firebase_auth.AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
  }

  Future<String?> _reauthenticateSocialUser() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final providerIds = user.providerData
        .map((item) => item.providerId)
        .toSet();
    if (providerIds.contains('google.com')) {
      await user.reauthenticateWithCredential(await _googleCredential());
    } else if (providerIds.contains('facebook.com')) {
      await user.reauthenticateWithCredential(await _facebookCredential());
    } else if (providerIds.contains('apple.com')) {
      await user.reauthenticateWithProvider(_appleProvider());
    } else {
      return null;
    }
    return user.getIdToken(true);
  }

  String _requirePendingSocialToken() {
    final token = _pendingSocialIdToken;
    if (token == null || token.isEmpty || _pendingSocialProvider == null) {
      throw const ValidationFailure('Start social sign-in again.');
    }
    return token;
  }

  void _clearPendingSocialAuth() {
    _pendingSocialIdToken = null;
    _pendingSocialProvider = null;
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
    required String city,
  }) {
    return _guard(() async {
      await _sessionDeadlineController.clearSession();
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
          'city': city,
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
        city: city,
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
    String? city,
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
              'city': ?city,
              'gender': ?gender,
              'birth_date': ?_dateOnly(birthDate),
            },
          )
          .then(_userFromPayloadAndCache);
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
          .then(_userFromPayloadAndCache);
    });
  }

  @override
  Future<ApiResult<bool>> logout() {
    return _guard(() async {
      try {
        final tokens = await _tokenStore.read();
        if (tokens != null) {
          await _apiClient.post<Object?>(
            ApiEndpoints.logout,
            data: {'refreshToken': tokens.refreshToken},
          );
        }
      } finally {
        await _sessionDeadlineController.clearSession();
        await _clearCachedUser();
        _clearPendingSocialAuth();
        if (Firebase.apps.isNotEmpty) {
          await firebase_auth.FirebaseAuth.instance.signOut();
        }
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
        try {
          await FacebookAuth.instance.logOut();
        } catch (_) {}
      }
      return true;
    });
  }

  @override
  Future<ApiResult<bool>> deleteAccount({required String password}) {
    return _guard(() async {
      final data = <String, dynamic>{};
      if (password.isNotEmpty) {
        data['password'] = password;
      } else {
        final idToken = await _reauthenticateSocialUser();
        if (idToken == null || idToken.isEmpty) {
          throw const ValidationFailure(
            'Sign in again before deleting this account.',
          );
        }
        data['id_token'] = idToken;
      }
      await _apiClient.delete<Map<String, dynamic>>(
        '/auth/client/profile/',
        data: data,
      );
      await _sessionDeadlineController.clearSession();
      await _clearCachedUser();
      if (Firebase.apps.isNotEmpty) {
        await firebase_auth.FirebaseAuth.instance.signOut();
      }
      return true;
    });
  }

  Future<AuthUser> _loadMe() async {
    final payload = await _apiClient.get<Map<String, dynamic>>('/auth/me');
    final user = _userFromPayload(payload);
    await _cacheUser(user);
    return user;
  }

  Future<AuthSession> _sessionFromPayload(Map<String, dynamic> payload) async {
    final user = _userFromPayload(payload);
    final tokensPayload = _asJsonMap(payload['tokens']) ?? payload;
    final tokens = tokensFromApiPayload(tokensPayload);
    await _tokenStore.save(tokens);
    await _sessionDeadlineController.activate(tokens);
    await _cacheUser(user);
    return _authSession(user, tokens);
  }

  bool _canRestoreOffline(DioException error) {
    final status = error.response?.statusCode;
    return error.response == null || (status != null && status >= 500);
  }

  Future<void> _cacheUser(AuthUser user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cachedUserKey, jsonEncode(user.toJson()));
  }

  Future<AuthUser?> _readCachedUser() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_cachedUserKey);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final payload = jsonDecode(encoded);
      if (payload is! Map) return null;
      final user = AuthUser.fromJson(Map<String, dynamic>.from(payload));
      return user.id.isEmpty ? null : user;
    } catch (_) {
      await preferences.remove(_cachedUserKey);
      return null;
    }
  }

  Future<void> _clearCachedUser() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_cachedUserKey);
  }

  AuthSession _authSession(AuthUser user, StoredAuthTokens tokens) {
    return AuthSession(
      user: user,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.accessExpiresAt,
      refreshExpiresAt: tokens.refreshExpiresAt,
      sessionStartedAt: tokens.sessionStartedAt,
      absoluteExpiresAt: tokens.absoluteExpiresAt,
      mode: tokens.mode,
    );
  }

  Future<AuthSession> _signupSessionFromPayload(
    Map<String, dynamic> payload, {
    required String firstName,
    required String lastName,
    required String email,
    String? username,
    String? phone,
    String? city,
  }) async {
    final user = _signupUserFromPayload(
      payload,
      firstName: firstName,
      lastName: lastName,
      email: email,
      username: username,
      phone: phone,
      city: city,
    );
    final tokens = _optionalTokensFromPayload(payload);
    if (tokens != null) {
      await _tokenStore.save(tokens);
      await _sessionDeadlineController.activate(tokens);
    }

    return AuthSession(
      user: user,
      accessToken: tokens?.accessToken,
      refreshToken: tokens?.refreshToken,
      expiresAt: tokens?.accessExpiresAt,
      refreshExpiresAt: tokens?.refreshExpiresAt,
      sessionStartedAt: tokens?.sessionStartedAt,
      absoluteExpiresAt: tokens?.absoluteExpiresAt,
      mode: tokens?.mode ?? AuthSessionMode.temporary,
      otpResendAfterSeconds: _intFromPayload(payload, 'resend_after_seconds'),
      registrationExpiresAt: _dateFromString(
        payload['registration_expires_at'],
      ),
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
      return _sessionFromPayload(payload);
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
      await _sessionDeadlineController.clearSession();
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
    String? city,
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
      city: _stringFromPayload(payload, 'city') ?? city?.trim(),
    );
  }

  OtpDeliveryResult _otpDeliveryResult(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final seconds = _intFromPayload(payload, 'resend_after_seconds');
      return OtpDeliveryResult(
        resendAfterSeconds: seconds,
        resendAvailableAt: _dateFromString(payload['resend_available_at']),
        registrationExpiresAt: _dateFromString(
          payload['registration_expires_at'],
        ),
      );
    }
    return const OtpDeliveryResult();
  }

  AuthUser _userFromPayload(Map<String, dynamic> payload) {
    final rawUser = payload['user'] ?? payload;
    return AuthUser.fromJson(_asJsonMap(rawUser) ?? const <String, dynamic>{});
  }

  Future<AuthUser> _userFromPayloadAndCache(
    Map<String, dynamic> payload,
  ) async {
    final user = _userFromPayload(payload);
    await _cacheUser(user);
    return user;
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
}
