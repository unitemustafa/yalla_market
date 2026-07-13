import 'auth_user.dart';
import '../../../../core/session/session_metadata.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.refreshExpiresAt,
    this.sessionStartedAt,
    this.absoluteExpiresAt,
    this.mode = AuthSessionMode.temporary,
    this.otpResendAfterSeconds,
  });

  final AuthUser user;
  final String? accessToken;
  final String? refreshToken;

  /// Access-token expiry supplied by the backend.
  final DateTime? expiresAt;
  final DateTime? refreshExpiresAt;
  final DateTime? sessionStartedAt;
  final DateTime? absoluteExpiresAt;
  final AuthSessionMode mode;
  final int? otpResendAfterSeconds;

  bool get isRemembered => mode.isRemembered;
}
