import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/features/auth/data/datasources/facebook_credential_data_source.dart';

void main() {
  test(
    'limited login sends the hash and binds the ID token to the raw nonce',
    () async {
      String? sentNonce;
      final source = FacebookCredentialDataSource(
        createNonce: () => 'request-specific-nonce',
        login: (hash) async {
          sentNonce = hash;
          return LoginResult(
            status: LoginStatus.success,
            accessToken: _limited(),
          );
        },
      );

      final credential = await source.createCredential();

      expect(
        sentNonce,
        sha256.convert(utf8.encode('request-specific-nonce')).toString(),
      );
      expect(sentNonce, isNot('request-specific-nonce'));
      expect(credential.providerId, 'facebook.com');
      expect(credential.signInMethod, 'oauth');
      expect(credential.idToken, 'limited-id-token');
      expect(credential.accessToken, isNull);
      expect(credential.asMap()['rawNonce'], 'request-specific-nonce');
    },
  );

  test(
    'classic login keeps the access token credential used on Android',
    () async {
      final source = FacebookCredentialDataSource(
        login: (_) async => LoginResult(
          status: LoginStatus.success,
          accessToken: ClassicToken(
            tokenString: 'classic-access-token',
            userId: 'test-user',
            applicationId: 'test-app',
            expires: DateTime.utc(2030),
            grantedPermissions: const ['email'],
            declinedPermissions: const [],
          ),
        ),
      );

      final credential = await source.createCredential();

      expect(credential.accessToken, 'classic-access-token');
      expect(credential.idToken, isNull);
      expect(credential.asMap()['rawNonce'], isNull);
    },
  );

  for (final result in [
    LoginResult(status: LoginStatus.cancelled),
    LoginResult(status: LoginStatus.failed),
    LoginResult(status: LoginStatus.success),
    LoginResult(
      status: LoginStatus.success,
      accessToken: _limited(token: '  '),
    ),
  ]) {
    test(
      'rejects ${result.status} with missing or invalid credentials',
      () async {
        final source = FacebookCredentialDataSource(login: (_) async => result);
        await expectLater(
          source.createCredential(),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );
  }

  test(
    'concurrent requests retain separate nonces when completed out of order',
    () async {
      var requests = 0;
      final firstResult = Completer<LoginResult>();
      final secondResult = Completer<LoginResult>();
      final source = FacebookCredentialDataSource(
        createNonce: () => 'nonce-${++requests}',
        login: (_) => requests == 1 ? firstResult.future : secondResult.future,
      );
      final first = source.createCredential();
      final second = source.createCredential();
      secondResult.complete(
        LoginResult(status: LoginStatus.success, accessToken: _limited()),
      );
      expect((await second).asMap()['rawNonce'], 'nonce-2');
      firstResult.complete(
        LoginResult(status: LoginStatus.success, accessToken: _limited()),
      );
      expect((await first).asMap()['rawNonce'], 'nonce-1');
    },
  );
}

LimitedToken _limited({String token = 'limited-id-token'}) => LimitedToken(
  tokenString: token,
  userId: 'test-user',
  userName: 'Test',
  userEmail: null,
  nonce: 'sdk-nonce',
);
