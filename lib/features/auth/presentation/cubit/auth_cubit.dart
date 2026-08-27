import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../app/routing/auth_guard.dart';
import '../../../../core/session/session_expired_notifier.dart';
import '../../../../core/session/account_inactive_notifier.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/otp/pending_verification_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._authUseCases, {
    SessionExpiredNotifier? sessionExpiredNotifier,
    AccountInactiveNotifier? accountInactiveNotifier,
    PushNotificationService? pushNotificationService,
    PendingVerificationStore? pendingVerificationStore,
  }) : _sessionExpiredNotifier =
           sessionExpiredNotifier ?? SessionExpiredNotifier.instance,
       _accountInactiveNotifier =
           accountInactiveNotifier ?? AccountInactiveNotifier.instance,
       _pushNotificationService = pushNotificationService,
       _pendingVerificationStore =
           pendingVerificationStore ?? const PendingVerificationStore(),
       super(
         (accountInactiveNotifier ?? AccountInactiveNotifier.instance)
                 .isInactive
             ? const AuthAccountDisabled()
             : const AuthInitial(),
       ) {
    _sessionExpiredNotifier.addListener(_handleSessionExpired);
    _accountInactiveNotifier.addListener(_handleInactiveAccount);
  }

  final AuthUseCases _authUseCases;
  final SessionExpiredNotifier _sessionExpiredNotifier;
  final AccountInactiveNotifier _accountInactiveNotifier;
  final PushNotificationService? _pushNotificationService;
  final PendingVerificationStore _pendingVerificationStore;
  String? _pendingVerificationEmail;
  DateTime? _pendingVerificationExpiresAt;
  AuthSession? _pendingSignupSession;
  String? _lastProfileUpdateError;
  String? _lastPasswordResetError;
  String? _lastAccountDeletionError;
  int? _lastOtpResendAfterSeconds;
  int? _lastOtpRetryAfterSeconds;

  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);
    if (change.nextState is AuthAuthenticated) {
      AuthGuard.setAuthenticated();
    } else if (change.nextState is AuthInitial ||
        change.nextState is AuthSignupSucceeded ||
        change.nextState is AuthVerificationRequired ||
        change.nextState is AuthSessionExpired) {
      AuthGuard.clearAuthentication();
    } else if (change.nextState is AuthAccountDisabled) {
      AuthGuard.clearAuthentication();
    }
  }

  bool get hasPendingSignup => _pendingVerificationEmail != null;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  String? get lastProfileUpdateError => _lastProfileUpdateError;
  String? get lastPasswordResetError => _lastPasswordResetError;
  String? get lastAccountDeletionError => _lastAccountDeletionError;
  int? get lastOtpResendAfterSeconds => _lastOtpResendAfterSeconds;
  int? get lastOtpRetryAfterSeconds => _lastOtpRetryAfterSeconds;

  @override
  Future<void> close() {
    _sessionExpiredNotifier.removeListener(_handleSessionExpired);
    _accountInactiveNotifier.removeListener(_handleInactiveAccount);
    return super.close();
  }

  void _handleInactiveAccount() {
    _pendingVerificationEmail = null;
    _pendingSignupSession = null;
    AuthGuard.clearAuthentication();
    if (!isClosed) {
      emit(const AuthAccountDisabled());
    }
  }

  Future<bool> validateSession() async {
    if (state is! AuthAuthenticated) return false;
    return await refreshProfile() != null;
  }

  void _handleSessionExpired() {
    _pendingVerificationEmail = null;
    _pendingSignupSession = null;
    AuthGuard.clearAuthentication();
    if (!isClosed) {
      emit(const AuthSessionExpired());
    }
  }

  void markSessionExpired() {
    _handleSessionExpired();
  }

  /// Hydrates auth state from an already-resolved session (e.g. from SplashCubit).
  void hydrate(AuthSession session) {
    _pendingVerificationEmail = null;
    _pendingSignupSession = null;
    unawaited(_pendingVerificationStore.clear());
    emit(AuthAuthenticated(session));
  }

  Future<bool> restoreSavedSession() async {
    if (state is AuthLoading) return false;

    _pendingVerificationEmail = null;
    _pendingSignupSession = null;
    emit(const AuthLoading());

    final result = await _authUseCases.restoreSavedSession();
    return result.when(
      success: (session) {
        if (session == null) {
          emit(const AuthInitial());
          return false;
        }

        if (!session.user.isActive) {
          _accountInactiveNotifier.notifyInactive();
          return false;
        }
        emit(AuthAuthenticated(session));
        return true;
      },
      failure: (_) {
        if (_accountInactiveNotifier.isInactive) return false;
        emit(const AuthInitial());
        return false;
      },
    );
  }

  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    if (state is AuthLoading) return;

    _pendingVerificationEmail = null;
    _pendingSignupSession = null;
    _accountInactiveNotifier.reset();
    emit(const AuthLoading());

    final result = await _authUseCases.login(
      email: email.trim(),
      password: password,
      rememberMe: rememberMe,
    );
    result.when(
      success: (session) {
        _accountInactiveNotifier.reset();
        _pendingVerificationEmail = null;
        _pendingSignupSession = null;
        unawaited(_pendingVerificationStore.clear());
        emit(AuthAuthenticated(session));
      },
      failure: (failure) {
        if (failure is EmailVerificationRequiredFailure) {
          _setPendingVerification(
            failure.email,
            expiresAt: failure.registrationExpiresAt,
          );
          _lastOtpRetryAfterSeconds = failure.retryAfterSeconds;
          emit(
            AuthVerificationRequired(
              failure.email,
              retryAfterSeconds: failure.retryAfterSeconds,
              registrationExpiresAt: failure.registrationExpiresAt,
            ),
          );
          return;
        }
        if (failure is AccountInactiveFailure) {
          emit(const AuthLoginAccountDisabled());
          return;
        }
        if (_accountInactiveNotifier.isInactive) return;
        emit(AuthFailure(failure.message));
      },
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
    final result = await _authUseCases.checkUsernameAvailability(
      username.trim(),
    );
    return result.when(
      success: (isAvailable) => isAvailable,
      failure: (failure) => throw failure,
    );
  }

  Future<bool> isEmailRegistered(String email) async {
    final result = await _authUseCases.checkEmailRegistration(email.trim());
    return result.when(
      success: (isRegistered) => isRegistered,
      failure: (_) => false,
    );
  }

  Future<bool> isEmailAvailable(String email) async {
    final result = await _authUseCases.checkEmailRegistration(email.trim());
    return result.when(
      success: (isRegistered) => !isRegistered,
      failure: (failure) => throw failure,
    );
  }

  Future<bool> isPhoneAvailable(String phone) async {
    final result = await _authUseCases.checkPhoneRegistration(phone.trim());
    return result.when(
      success: (isRegistered) => !isRegistered,
      failure: (failure) => throw failure,
    );
  }

  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    required String phone,
    required String city,
  }) async {
    if (state is AuthLoading) return;

    _pendingVerificationEmail = null;
    _pendingSignupSession = null;
    emit(const AuthLoading());

    final result = await _authUseCases.signup(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      password: password,
      username: username.trim(),
      phone: phone.trim(),
      city: city.trim(),
    );
    result.when(
      success: (session) {
        _pendingSignupSession = session;
        final createdEmail = session.user.email.trim().isEmpty
            ? email.trim()
            : session.user.email.trim();
        _setPendingVerification(
          createdEmail,
          expiresAt: session.registrationExpiresAt,
        );
        _lastOtpResendAfterSeconds = session.otpResendAfterSeconds;
        _lastOtpRetryAfterSeconds = null;
        emit(AuthSignupSucceeded(createdEmail));
      },
      failure: (failure) {
        if (failure is EmailVerificationRequiredFailure) {
          _setPendingVerification(
            failure.email,
            expiresAt: failure.registrationExpiresAt,
          );
          _lastOtpRetryAfterSeconds = failure.retryAfterSeconds;
          emit(
            AuthVerificationRequired(
              failure.email,
              retryAfterSeconds: failure.retryAfterSeconds,
              registrationExpiresAt: failure.registrationExpiresAt,
            ),
          );
          return;
        }
        emit(AuthFailure(failure.message));
      },
    );
  }

  Future<bool> completeSignupVerification(String code, {String? email}) async {
    if (await _clearExpiredPendingVerification()) return false;
    final verificationEmail = email?.trim().isNotEmpty == true
        ? email!.trim()
        : _pendingVerificationEmail;
    if (verificationEmail == null || verificationEmail.isEmpty) return false;
    _pendingVerificationEmail = verificationEmail;
    final pendingSession = _pendingSignupSession;
    if (pendingSession?.accessToken != null &&
        pendingSession?.refreshToken != null) {
      _pendingSignupSession = null;
      _pendingVerificationEmail = null;
      unawaited(_pendingVerificationStore.clear());
      emit(AuthAuthenticated(pendingSession!));
      return true;
    }

    emit(const AuthLoading());
    final result = await _authUseCases.verifyEmail(
      email: verificationEmail,
      code: code.trim(),
    );
    return result.when(
      success: (verifiedSession) {
        _pendingVerificationEmail = null;
        _pendingSignupSession = null;
        unawaited(_pendingVerificationStore.clear());
        emit(AuthAuthenticated(verifiedSession));
        return true;
      },
      failure: (failure) {
        emit(AuthFailure(failure.message));
        return false;
      },
    );
  }

  Future<bool> resendSignupVerificationCode({String? email}) async {
    if (await _clearExpiredPendingVerification()) return false;
    final verificationEmail = email?.trim().isNotEmpty == true
        ? email!.trim()
        : _pendingVerificationEmail;
    if (verificationEmail == null || verificationEmail.isEmpty) return false;
    _pendingVerificationEmail = verificationEmail;

    final result = await _authUseCases.resendVerificationCode(
      verificationEmail,
    );
    return result.when(
      success: (delivery) {
        _lastOtpResendAfterSeconds = delivery.resendAfterSeconds;
        _lastOtpRetryAfterSeconds = null;
        _setPendingVerification(
          verificationEmail,
          expiresAt: delivery.registrationExpiresAt,
        );
        return delivery.sent;
      },
      failure: (failure) {
        _storeOtpFailure(failure);
        emit(AuthFailure(failure.message));
        return false;
      },
    );
  }

  void hydratePendingVerification(String email, {DateTime? expiresAt}) {
    _pendingSignupSession = null;
    _setPendingVerification(email, expiresAt: expiresAt);
    emit(AuthVerificationRequired(email, registrationExpiresAt: expiresAt));
  }

  Future<void> abandonPendingVerification() async {
    _pendingVerificationEmail = null;
    _pendingVerificationExpiresAt = null;
    _pendingSignupSession = null;
    await _pendingVerificationStore.clear();
    emit(const AuthInitial());
  }

  void _setPendingVerification(String email, {DateTime? expiresAt}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final isSameRegistration = _pendingVerificationEmail == normalized;
    final effectiveExpiry =
        expiresAt ??
        (isSameRegistration ? _pendingVerificationExpiresAt : null) ??
        DateTime.now().toUtc().add(const Duration(hours: 24));
    _pendingVerificationEmail = normalized;
    _pendingVerificationExpiresAt = effectiveExpiry;
    unawaited(
      _pendingVerificationStore.save(
        email: normalized,
        expiresAt: effectiveExpiry,
      ),
    );
  }

  Future<bool> _clearExpiredPendingVerification() async {
    final email = _pendingVerificationEmail;
    final expiresAt = _pendingVerificationExpiresAt;
    if (email == null ||
        expiresAt == null ||
        expiresAt.isAfter(DateTime.now().toUtc())) {
      return false;
    }
    _pendingVerificationEmail = null;
    _pendingVerificationExpiresAt = null;
    _pendingSignupSession = null;
    await _pendingVerificationStore.clear();
    emit(const AuthInitial());
    return true;
  }

  Future<bool> requestPasswordReset(String email) async {
    final currentState = state;
    final result = await _authUseCases.requestPasswordReset(email.trim());
    return result.when(
      success: (sent) {
        _lastOtpResendAfterSeconds = sent.resendAfterSeconds;
        _lastOtpRetryAfterSeconds = null;
        _lastPasswordResetError = null;
        return sent.sent;
      },
      failure: (failure) {
        _storeOtpFailure(failure);
        _lastPasswordResetError = failure.message;
        if (currentState is! AuthAuthenticated &&
            state is! AuthSessionExpired &&
            state is! AuthAccountDisabled) {
          emit(AuthFailure(failure.message));
        }
        return false;
      },
    );
  }

  Future<bool> resendPasswordResetCode(String email) async {
    final currentState = state;
    final result = await _authUseCases.resendPasswordResetCode(email.trim());
    return result.when(
      success: (sent) {
        _lastOtpResendAfterSeconds = sent.resendAfterSeconds;
        _lastOtpRetryAfterSeconds = null;
        _lastPasswordResetError = null;
        return sent.sent;
      },
      failure: (failure) {
        _storeOtpFailure(failure);
        _lastPasswordResetError = failure.message;
        if (currentState is! AuthAuthenticated &&
            state is! AuthSessionExpired &&
            state is! AuthAccountDisabled) {
          emit(AuthFailure(failure.message));
        }
        return false;
      },
    );
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirm,
  }) async {
    if (state is AuthLoading) return false;

    final currentState = state;
    emit(const AuthLoading());
    final result = await _authUseCases.resetPassword(
      email: email.trim(),
      code: code.trim(),
      password: password,
      passwordConfirm: passwordConfirm,
    );
    return result.when(
      success: (_) {
        _lastPasswordResetError = null;
        emit(const AuthInitial());
        return true;
      },
      failure: (failure) {
        _lastPasswordResetError = failure.message;
        if (state is AuthSessionExpired || state is AuthAccountDisabled) {
          return false;
        }
        if (currentState is AuthAuthenticated) {
          emit(currentState);
        } else {
          emit(AuthFailure(failure.message));
        }
        return false;
      },
    );
  }

  Future<void> logout() async {
    _pendingVerificationEmail = null;
    _pendingSignupSession = null;
    unawaited(_pendingVerificationStore.clear());
    await _pushNotificationService?.unregisterCurrentDevice();
    final result = await _authUseCases.logout();
    result.when(
      success: (_) => emit(const AuthInitial()),
      failure: (_) {
        // Cannot show the old session without emitting; go to initial so
        // the UI is consistent. A snackbar is shown at the call site.
        emit(const AuthInitial());
      },
    );
  }

  Future<bool> deleteAccount(String password) async {
    if (state is! AuthAuthenticated) return false;

    _lastAccountDeletionError = null;
    final result = await _authUseCases.deleteAccount(password: password);
    return result.when(
      success: (_) {
        _pendingVerificationEmail = null;
        _pendingSignupSession = null;
        unawaited(_pendingVerificationStore.clear());
        emit(const AuthInitial());
        return true;
      },
      failure: (failure) {
        _lastAccountDeletionError = failure.message;
        return false;
      },
    );
  }

  Future<AuthUser?> refreshProfile() async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return null;

    final result = await _authUseCases.refreshProfile();
    return result.when(
      success: (user) {
        final activeState = state;
        if (activeState is! AuthAuthenticated) return null;
        _lastProfileUpdateError = null;
        emit(AuthAuthenticated(_sessionWithUser(activeState.session, user)));
        return user;
      },
      failure: (_) => null,
    );
  }

  Future<AuthUser?> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? gender,
    DateTime? birthDate,
  }) async {
    final currentState = state;
    final result = await _authUseCases.updateProfile(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      phone: phone,
      gender: gender,
      birthDate: birthDate,
    );
    return result.when(
      success: (user) {
        final activeState = state;
        if (currentState is AuthAuthenticated &&
            activeState is! AuthAuthenticated) {
          return null;
        }
        _lastProfileUpdateError = null;
        final nextSession = activeState is AuthAuthenticated
            ? _sessionWithUser(activeState.session, user)
            : AuthSession(user: user);
        emit(AuthAuthenticated(nextSession));
        return user;
      },
      failure: (failure) {
        _lastProfileUpdateError = failure.message;
        if (currentState is! AuthAuthenticated &&
            state is! AuthSessionExpired &&
            state is! AuthAccountDisabled) {
          emit(AuthFailure(failure.message));
        }
        return null;
      },
    );
  }

  Future<AuthUser?> updateProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return null;

    final result = await _authUseCases.updateProfileAvatar(
      bytes: bytes,
      fileName: fileName,
    );
    return result.when(
      success: (user) {
        final activeState = state;
        if (activeState is! AuthAuthenticated) return null;
        _lastProfileUpdateError = null;
        emit(AuthAuthenticated(_sessionWithUser(activeState.session, user)));
        return user;
      },
      failure: (failure) {
        _lastProfileUpdateError = failure.message;
        return null;
      },
    );
  }

  AuthSession _sessionWithUser(AuthSession session, AuthUser user) {
    return AuthSession(
      user: user,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
      refreshExpiresAt: session.refreshExpiresAt,
      sessionStartedAt: session.sessionStartedAt,
      absoluteExpiresAt: session.absoluteExpiresAt,
      mode: session.mode,
    );
  }

  void _storeOtpFailure(Failure failure) {
    if (failure is OtpCooldownFailure) {
      _lastOtpRetryAfterSeconds = failure.retryAfterSeconds;
    } else {
      _lastOtpRetryAfterSeconds = null;
    }
  }
}
