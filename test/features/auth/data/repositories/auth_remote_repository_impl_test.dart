import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/session/session_metadata.dart';
import 'package:yalla_market/core/storage/token_store.dart';
import 'package:yalla_market/features/auth/data/repositories/auth_remote_repository_impl.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_user.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('AuthRemoteRepositoryImpl', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('login stores secure tokens when remember me is enabled', () async {
      final tokenStore = InMemoryTokenStore();
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'POST');
        expect(request.path, '/auth/login/client');
        expect(request.data, {
          'identifier': 'm@example.com',
          'password': 'Password123!',
          'remember': true,
        });
        return _sessionPayload(remembered: true);
      });
      final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

      final result = await repository.login(
        email: 'm@example.com',
        password: 'Password123!',
        rememberMe: true,
      );

      result.when(
        success: (session) {
          expect(session.user.email, 'm@example.com');
          expect(session.accessToken, 'access-token');
        },
        failure: (failure) => fail(failure.message),
      );
      final stored = await tokenStore.read();
      expect(stored?.refreshToken, 'refresh-token');
      expect(stored?.mode, AuthSessionMode.persistent);
      expect(stored?.absoluteExpiresAt, isNull);
      expect(
        stored?.refreshExpiresAt.difference(stored.sessionStartedAt),
        const Duration(days: 7),
      );
    });

    test(
      'login keeps tokens session-only when remember me is disabled',
      () async {
        final tokenStore = InMemoryTokenStore();
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'POST');
          expect(request.path, '/auth/login/client');
          expect(request.data, {
            'identifier': 'm@example.com',
            'password': 'Password123!',
            'remember': false,
          });
          return _sessionPayload(remembered: false);
        });
        final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

        final result = await repository.login(
          email: 'm@example.com',
          password: 'Password123!',
        );

        result.when(
          success: (session) {
            expect(session.user.email, 'm@example.com');
            expect(session.accessToken, 'access-token');
          },
          failure: (failure) => fail(failure.message),
        );
        final stored = await tokenStore.read();
        expect(stored?.refreshToken, 'refresh-token');
        expect(stored?.mode, AuthSessionMode.temporary);
        expect(
          stored?.absoluteExpiresAt?.difference(stored.sessionStartedAt),
          const Duration(hours: 8),
        );
      },
    );

    test(
      'temporary session is absent after a mobile process restart',
      () async {
        final tokenStore = InMemoryTokenStore();
        final apiClient = FakeApiClient(
          (request) => _sessionPayload(remembered: false),
        );
        final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

        await repository.login(
          email: 'm@example.com',
          password: 'Password123!',
        );

        final restartedRepository = AuthRemoteRepositoryImpl(
          FakeApiClient(
            (request) => fail('Should not call API without tokens.'),
          ),
          InMemoryTokenStore(),
        );
        final result = await restartedRepository.restoreSavedSession();

        result.when(
          success: (session) => expect(session, isNull),
          failure: (failure) => fail(failure.message),
        );
      },
    );

    test(
      'signup accepts verification-only responses without storing tokens',
      () async {
        final tokenStore = InMemoryTokenStore();
        await tokenStore.save(_storedTokens(remembered: false));
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'POST');
          expect(request.path, '/auth/signup');
          expect(request.data, {
            'first_name': 'Mustafa',
            'last_name': 'Ali',
            'username': 'mustafa_ali',
            'email': 'mustafa@example.com',
            'phone': '+201000000000',
            'password': 'Password123!',
            'password_confirm': 'Password123!',
            'terms_accepted': true,
          });
          return {
            'email': 'mustafa@example.com',
            'message': 'Verification email sent',
          };
        });
        final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

        final result = await repository.signup(
          firstName: 'Mustafa',
          lastName: 'Ali',
          email: 'mustafa@example.com',
          password: 'Password123!',
          username: 'mustafa_ali',
          phone: '+201000000000',
        );

        result.when(
          success: (session) {
            expect(session.user.email, 'mustafa@example.com');
            expect(session.accessToken, isNull);
          },
          failure: (failure) => fail(failure.message),
        );
        expect(await tokenStore.read(), isNull);
      },
    );

    test(
      'restoreSavedSession clears legacy auth and loads current user',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth.local_session': '{}',
          'auth.local_accounts': '[]',
        });
        final tokenStore = InMemoryTokenStore();
        await tokenStore.save(_storedTokens(remembered: true));
        final apiClient = FakeApiClient((request) {
          expect(request.path, '/auth/me');
          return {'user': _userPayload};
        });
        final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

        final result = await repository.restoreSavedSession();

        result.when(
          success: (session) => expect(session?.user.email, 'm@example.com'),
          failure: (failure) => fail(failure.message),
        );
        final preferences = await SharedPreferences.getInstance();
        expect(preferences.containsKey('auth.local_session'), isFalse);
        expect(preferences.containsKey('auth.local_accounts'), isFalse);
      },
    );

    test('verifyEmail posts the code and stores session-only tokens', () async {
      final tokenStore = InMemoryTokenStore();
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'POST');
        expect(request.path, '/auth/verify-email');
        expect(request.data, {'email': 'm@example.com', 'otp': '123456'});
        return _sessionPayload(remembered: false);
      });
      final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

      final result = await repository.verifyEmail(
        email: 'm@example.com',
        code: '123456',
      );

      result.when(
        success: (session) {
          expect(session.user.email, 'm@example.com');
          expect(session.accessToken, 'access-token');
        },
        failure: (failure) => fail(failure.message),
      );
      expect((await tokenStore.read())?.mode, AuthSessionMode.temporary);
    });

    test(
      'logout sends the refresh token before clearing local tokens',
      () async {
        final tokenStore = InMemoryTokenStore();
        await tokenStore.save(_storedTokens(remembered: false));
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'POST');
          expect(request.path, '/auth/logout');
          expect(request.data, {'refreshToken': 'refresh-token'});
          return true;
        });
        final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

        final result = await repository.logout();

        result.when(
          success: (loggedOut) => expect(loggedOut, isTrue),
          failure: (failure) => fail(failure.message),
        );
        expect(await tokenStore.read(), isNull);
      },
    );

    test('logout clears local tokens when the backend request fails', () async {
      final tokenStore = InMemoryTokenStore();
      await tokenStore.save(_storedTokens(remembered: true));
      final apiClient = FakeApiClient((request) {
        throw DioException(
          requestOptions: RequestOptions(path: request.path),
          type: DioExceptionType.connectionError,
        );
      });
      final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

      final result = await repository.logout();

      result.when(
        success: (_) => fail('The network failure should still be reported.'),
        failure: (_) {},
      );
      expect(await tokenStore.read(), isNull);
    });

    test('updateProfile sends profile fields supported by backend', () async {
      final tokenStore = InMemoryTokenStore();
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'PATCH');
        expect(request.path, '/auth/client/profile/');
        expect(request.data, {
          'first_name': 'Mustafa',
          'last_name': 'Ali',
          'username': 'mustafa_ali',
          'email': 'm@example.com',
          'phone': '+201234567890',
          'gender': 'male',
          'birth_date': '1995-04-12',
        });
        return {
          ..._userPayload,
          'first_name': 'Mustafa',
          'last_name': 'Ali',
          'username': 'mustafa_ali',
          'phone': '+201234567890',
          'gender': 'male',
          'birth_date': '1995-04-12',
          'username_changed_at': '2026-06-23T10:00:00Z',
        };
      });
      final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

      final result = await repository.updateProfile(
        firstName: 'Mustafa',
        lastName: 'Ali',
        username: 'mustafa_ali',
        email: 'm@example.com',
        phone: '+201234567890',
        gender: 'male',
        birthDate: DateTime(1995, 4, 12),
      );

      result.when(
        success: (user) {
          expect(user.username, 'mustafa_ali');
          expect(user.gender, 'male');
          expect(user.birthDate, DateTime(1995, 4, 12));
          expect(user.usernameChangedAt, isNotNull);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('updateProfileAvatar sends multipart avatar with filename', () async {
      final tokenStore = InMemoryTokenStore();
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'PATCH');
        expect(request.path, '/auth/client/profile/');
        final formData = request.data as FormData;
        expect(formData.files, hasLength(1));
        expect(formData.files.single.key, 'avatar');
        expect(formData.files.single.value.filename, 'avatar.png');
        return {
          ..._userPayload,
          'avatar_url': 'https://example.com/avatar.png',
        };
      });
      final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

      final result = await repository.updateProfileAvatar(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.png',
      );

      result.when(
        success: (user) =>
            expect(user.avatarUrl, 'https://example.com/avatar.png'),
        failure: (failure) => fail(failure.message),
      );
    });

    test('AuthUser parses string and integer ids from backend payloads', () {
      final stringIdUser = AuthUser.fromJson({..._userPayload, 'id': '15'});
      final integerIdUser = AuthUser.fromJson({
        ..._userPayload,
        'id': 15,
        'phone': 213555100002,
        'avatar_url': 123,
      });

      expect(stringIdUser.id, '15');
      expect(integerIdUser.id, '15');
      expect(integerIdUser.phone, '213555100002');
      expect(integerIdUser.avatarUrl, '123');
    });

    test('requestPasswordReset posts the email', () async {
      final tokenStore = InMemoryTokenStore();
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'POST');
        expect(request.path, '/auth/forgot-password');
        expect(request.data, {'email': 'm@example.com'});
        return {
          'detail':
              'If an active account exists, a password reset OTP has been sent.',
          'resend_after_seconds': 30,
        };
      });
      final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

      final result = await repository.requestPasswordReset('m@example.com');

      result.when(
        success: (sent) {
          expect(sent.sent, isTrue);
          expect(sent.resendAfterSeconds, 30);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test(
      'resetPassword posts otp and new password then clears tokens',
      () async {
        final tokenStore = InMemoryTokenStore();
        await tokenStore.save(_storedTokens(remembered: false));
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'POST');
          expect(request.path, '/auth/reset-password');
          expect(request.data, {
            'email': 'm@example.com',
            'otp': '123456',
            'password': 'NewPassword123!',
            'password_confirm': 'NewPassword123!',
          });
          return {'detail': 'Password reset successfully.'};
        });
        final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

        final result = await repository.resetPassword(
          email: 'm@example.com',
          code: '123456',
          password: 'NewPassword123!',
          passwordConfirm: 'NewPassword123!',
        );

        result.when(
          success: (reset) => expect(reset, isTrue),
          failure: (failure) => fail(failure.message),
        );
        expect(await tokenStore.read(), isNull);
      },
    );
  });
}

Map<String, dynamic> _sessionPayload({required bool remembered}) {
  final startedAt = DateTime.now().toUtc();
  final refreshExpiresAt = startedAt.add(
    remembered ? const Duration(days: 7) : const Duration(hours: 8),
  );
  return {
    'user': _userPayload,
    'accessToken': 'access-token',
    'refreshToken': 'refresh-token',
    'expiresIn': 900,
    'session': {
      'mode': remembered ? 'persistent' : 'temporary',
      'remember': remembered,
      'startedAt': startedAt.toIso8601String(),
      'absoluteExpiresAt': remembered
          ? null
          : refreshExpiresAt.toIso8601String(),
      'accessExpiresAt': startedAt
          .add(const Duration(minutes: 15))
          .toIso8601String(),
      'refreshExpiresAt': refreshExpiresAt.toIso8601String(),
    },
  };
}

StoredAuthTokens _storedTokens({required bool remembered}) {
  final startedAt = DateTime.now().toUtc();
  final refreshExpiresAt = startedAt.add(
    remembered ? const Duration(days: 7) : const Duration(hours: 8),
  );
  return StoredAuthTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessExpiresAt: startedAt.add(const Duration(minutes: 15)),
    refreshExpiresAt: refreshExpiresAt,
    sessionStartedAt: startedAt,
    mode: remembered ? AuthSessionMode.persistent : AuthSessionMode.temporary,
    absoluteExpiresAt: remembered ? null : refreshExpiresAt,
  );
}

const _userPayload = {
  'id': 'user-1',
  'email': 'm@example.com',
  'firstName': 'Mustafa',
  'lastName': 'Ali',
  'role': 'CUSTOMER',
};
