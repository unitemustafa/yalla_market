import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../../../../core/errors/failure.dart';

class FacebookCredentialDataSource {
  FacebookCredentialDataSource({
    Future<LoginResult> Function(String nonceHash)? login,
    String Function()? createNonce,
  }) : _login = login ?? _facebookLogin,
       _createNonce = createNonce ?? _secureNonce;

  final Future<LoginResult> Function(String nonceHash) _login;
  final String Function() _createNonce;

  Future<OAuthCredential> createCredential() async {
    // Keep the original nonce local to this request, including concurrent calls.
    final rawNonce = _createNonce();
    final nonceHash = sha256.convert(utf8.encode(rawNonce)).toString();
    final result = await _login(nonceHash);
    final token = result.accessToken;
    if (result.status != LoginStatus.success || token == null) {
      throw ValidationFailure(
        result.status == LoginStatus.cancelled
            ? 'Facebook sign-in was cancelled.'
            : 'Facebook sign-in could not be completed.',
      );
    }
    if (token.tokenString.trim().isEmpty) {
      throw const ValidationFailure(
        'Facebook did not return an identity token.',
      );
    }
    if (token.type == AccessTokenType.limited) {
      return OAuthProvider(
        'facebook.com',
      ).credential(idToken: token.tokenString, rawNonce: rawNonce);
    }
    return FacebookAuthProvider.credential(token.tokenString);
  }

  static Future<LoginResult> _facebookLogin(String nonceHash) {
    return FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
      loginTracking: LoginTracking.limited,
      nonce: nonceHash,
    );
  }

  static String _secureNonce() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => random.nextInt(256)));
  }
}
