import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.otpResendAfterSeconds,
  });

  final AuthUser user;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final int? otpResendAfterSeconds;
}
