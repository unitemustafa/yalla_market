import '../../domain/entities/auth_session.dart';
import '../../domain/entities/social_auth_result.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final AuthSession session;
}

final class AuthSocialProfileRequired extends AuthState {
  const AuthSocialProfileRequired(this.result);

  final SocialAuthResult result;
}

final class AuthSocialLinkRequired extends AuthState {
  const AuthSocialLinkRequired(this.result);

  final SocialAuthResult result;
}

final class AuthSignupSucceeded extends AuthState {
  const AuthSignupSucceeded(this.email);

  final String email;
}

final class AuthVerificationRequired extends AuthState {
  const AuthVerificationRequired(
    this.email, {
    this.retryAfterSeconds,
    this.registrationExpiresAt,
  });

  final String email;
  final int? retryAfterSeconds;
  final DateTime? registrationExpiresAt;
}

final class AuthSessionExpired extends AuthState {
  const AuthSessionExpired();
}

final class AuthAccountDisabled extends AuthState {
  const AuthAccountDisabled();
}

final class AuthLoginAccountDisabled extends AuthState {
  const AuthLoginAccountDisabled();
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;
}
