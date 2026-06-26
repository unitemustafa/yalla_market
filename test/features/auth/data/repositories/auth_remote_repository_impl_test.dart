import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/storage/token_store.dart';
import 'package:yalla_market/features/auth/data/repositories/auth_remote_repository_impl.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('AuthRemoteRepositoryImpl', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('login stores secure tokens when remember me is enabled', () async {
      final startedAt = DateTime.now();
      final tokenStore = InMemoryTokenStore();
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'POST');
        expect(request.path, '/auth/login');
        return _sessionPayload;
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
      expect((await tokenStore.read())?.refreshToken, 'refresh-token');
      expect((await tokenStore.read())?.isSessionOnly, isFalse);
      expect(
        (await tokenStore.read())?.expiresAt.isAfter(
          startedAt.add(const Duration(days: 29)),
        ),
        isTrue,
      );
    });

    test(
      'login keeps tokens session-only when remember me is disabled',
      () async {
        final startedAt = DateTime.now();
        final tokenStore = InMemoryTokenStore();
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'POST');
          expect(request.path, '/auth/login');
          return _sessionPayload;
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
        expect((await tokenStore.read())?.refreshToken, 'refresh-token');
        expect((await tokenStore.read())?.isSessionOnly, isTrue);
        expect(
          (await tokenStore.read())?.expiresAt.isAfter(
            startedAt.add(const Duration(hours: 7)),
          ),
          isTrue,
        );
      },
    );

    test(
      'restoreSavedSession reports a closed session-only login as expired',
      () async {
        final tokenStore = InMemoryTokenStore();
        final apiClient = FakeApiClient((request) => _sessionPayload);
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
          success: (_) => fail('Closed session-only login should expire.'),
          failure: (failure) {
            expect(failure, isA<UnauthorizedFailure>());
            expect(failure.message, 'Session expired.');
          },
        );
      },
    );

    test(
      'signup accepts verification-only responses without storing tokens',
      () async {
        final tokenStore = InMemoryTokenStore();
        await tokenStore.save(
          StoredAuthTokens(
            accessToken: 'old-access-token',
            refreshToken: 'old-refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'POST');
          expect(request.path, '/auth/signup');
          expect(request.data, {
            'first_name': 'Mustafa',
            'last_name': 'Ali',
            'email': 'mustafa@example.com',
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
        await tokenStore.save(
          StoredAuthTokens(
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );
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
        return _sessionPayload;
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
      expect((await tokenStore.read())?.isSessionOnly, isTrue);
    });

    test(
      'logout sends the refresh token before clearing local tokens',
      () async {
        final tokenStore = InMemoryTokenStore();
        await tokenStore.save(
          StoredAuthTokens(
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );
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

    test('deleteAccountWithPassword calls auth me delete endpoint', () async {
      final tokenStore = InMemoryTokenStore();
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'DELETE');
        expect(request.path, '/auth/me');
        expect(request.data, {'password': 'Password123!'});
        return true;
      });
      final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

      final result = await repository.deleteAccountWithPassword('Password123!');

      result.when(
        success: (deleted) => expect(deleted, isTrue),
        failure: (failure) => fail(failure.message),
      );
    });

    test('updateProfile sends profile fields supported by backend', () async {
      final tokenStore = InMemoryTokenStore();
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'PATCH');
        expect(request.path, '/auth/me');
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

    test('requestPasswordReset posts the email', () async {
      final tokenStore = InMemoryTokenStore();
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'POST');
        expect(request.path, '/auth/forgot-password');
        expect(request.data, {'email': 'm@example.com'});
        return {
          'detail':
              'If an active account exists, a password reset OTP has been sent.',
        };
      });
      final repository = AuthRemoteRepositoryImpl(apiClient, tokenStore);

      final result = await repository.requestPasswordReset('m@example.com');

      result.when(
        success: (sent) => expect(sent, isTrue),
        failure: (failure) => fail(failure.message),
      );
    });

    test(
      'resetPassword posts otp and new password then clears tokens',
      () async {
        final tokenStore = InMemoryTokenStore();
        await tokenStore.save(
          StoredAuthTokens(
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );
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

final _sessionPayload = {
  'user': _userPayload,
  'accessToken': 'access-token',
  'refreshToken': 'refresh-token',
  'expiresIn': 3600,
};

const _userPayload = {
  'id': 'user-1',
  'email': 'm@example.com',
  'firstName': 'Mustafa',
  'lastName': 'Ali',
  'role': 'CUSTOMER',
};
