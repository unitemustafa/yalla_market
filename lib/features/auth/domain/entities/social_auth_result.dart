import 'auth_session.dart';

enum SocialAuthProvider {
  google,
  facebook,
  apple;

  String get displayName => switch (this) {
    SocialAuthProvider.google => 'Google',
    SocialAuthProvider.facebook => 'Facebook',
    SocialAuthProvider.apple => 'Apple',
  };
}

enum SocialAuthAction { authenticated, completeProfile, linkAccount }

class SocialAuthResult {
  const SocialAuthResult({
    required this.action,
    required this.provider,
    required this.email,
    this.session,
    this.firstName = '',
    this.lastName = '',
    this.avatarUrl,
    this.emailVerified = false,
  });

  final SocialAuthAction action;
  final SocialAuthProvider provider;
  final String email;
  final AuthSession? session;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final bool emailVerified;
}
