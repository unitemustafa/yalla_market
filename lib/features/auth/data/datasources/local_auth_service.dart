import 'dart:typed_data';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/otp_delivery_result.dart';
import '../models/local_auth_account.dart';
import 'local_auth_store.dart';
import 'local_auth_value_helpers.dart';

class LocalAuthService {
  static const Duration _rememberedSessionDuration = Duration(days: 7);
  static const Duration _temporarySessionDuration = Duration(hours: 8);
  static const Set<String> _reservedUsernames = {
    'admin',
    'support',
    'yallamarket',
    'taken_user',
  };

  final LocalAuthStore _store = LocalAuthStore();
  AuthSession? _session;
  DateTime? _sessionExpiresAt;

  Future<AuthSession?> restoreSavedSession() async {
    if (_session != null && !_sessionHasExpired()) return _session;
    if (_sessionHasExpired()) {
      await _clearSession();
      throw const UnauthorizedFailure('Session expired.');
    }

    final storedSession = await _store.loadSession();
    if (storedSession == null) return null;

    _sessionExpiresAt = storedSession.expiresAt;
    if (_sessionHasExpired()) {
      await _clearSession();
      throw const UnauthorizedFailure('Session expired.');
    }

    final account = (await _store.loadAccounts()).byUserId(
      storedSession.user.id,
    );
    if (account == null) {
      await _clearSession();
      return null;
    }

    _session = AuthSession(user: account.user);
    return _session;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final identifier = email.trim();
    if (identifier.isEmpty || password.isEmpty) {
      throw const ValidationFailure(
        'Email, username, or phone number and password are required.',
      );
    }

    final account = (await _store.loadAccounts()).byLoginIdentifier(identifier);
    if (account == null ||
        account.passwordDigest != localAuthPasswordDigest(password)) {
      throw const UnauthorizedFailure('Invalid email or password.');
    }

    return _startSession(account.user, rememberSession: rememberMe);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final normalized = normalizeAuthUsername(username);
    if (normalized.isEmpty) return true;
    if (_reservedUsernames.contains(normalized)) return false;

    final currentUserId = _session?.user.id;
    return !(await _store.loadAccounts()).any(
      (account) =>
          account.user.id != currentUserId &&
          normalizeAuthUsername(account.user.username ?? '') == normalized,
    );
  }

  Future<bool> isEmailRegistered(String email) async {
    final normalized = normalizeAuthEmail(email);
    if (normalized.isEmpty) return false;
    return (await _store.loadAccounts()).byEmail(normalized) != null;
  }

  Future<bool> isPhoneRegistered(String phone) async {
    final normalized = normalizeAuthPhone(phone);
    if (normalized.isEmpty) return false;
    return (await _store.loadAccounts()).any(
      (account) => normalizeAuthPhone(account.user.phone ?? '') == normalized,
    );
  }

  Future<AuthSession> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    required String phone,
  }) async {
    final normalizedEmail = normalizeAuthEmail(email);
    final normalizedUsername = normalizeAuthUsername(username);
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();

    if (cleanFirstName.isEmpty ||
        cleanLastName.isEmpty ||
        normalizedEmail.isEmpty ||
        password.isEmpty ||
        normalizedUsername.isEmpty ||
        phone.trim().isEmpty) {
      throw const ValidationFailure(
        'Name, username, email, phone, and password are required.',
      );
    }

    final accounts = await _store.loadAccounts();
    if (accounts.byEmail(normalizedEmail) != null) {
      throw const ValidationFailure('Email is already registered.');
    }
    if (await isPhoneRegistered(phone)) {
      throw const ValidationFailure('Phone number is already registered.');
    }
    if (!await isUsernameAvailable(normalizedUsername)) {
      throw const ValidationFailure('Username is not available.');
    }

    final user = AuthUser(
      id: localAuthUserId(normalizedEmail),
      email: normalizedEmail,
      firstName: cleanFirstName,
      lastName: cleanLastName,
      username: normalizedUsername,
      phone: phone.trim(),
      role: 'CUSTOMER',
    );

    await _store.saveAccounts([
      ...accounts,
      LocalAuthAccount(
        user: user,
        passwordDigest: localAuthPasswordDigest(password),
      ),
    ]);
    final session = await _startSession(user, rememberSession: false);
    return AuthSession(
      user: session.user,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
      otpResendAfterSeconds: 30,
    );
  }

  Future<AuthSession> verifyEmail({
    required String email,
    required String code,
  }) async {
    final normalizedEmail = normalizeAuthEmail(email);
    final normalizedCode = code.trim();
    if (normalizedEmail.isEmpty ||
        !RegExp(r'^\d{6}$').hasMatch(normalizedCode)) {
      throw const ValidationFailure('Enter the 6-digit verification code.');
    }

    final currentSession = _session;
    if (currentSession != null &&
        normalizeAuthEmail(currentSession.user.email) == normalizedEmail) {
      return currentSession;
    }

    final account = (await _store.loadAccounts()).byEmail(normalizedEmail);
    if (account == null) {
      throw const UnauthorizedFailure('No local user session.');
    }
    return _startSession(account.user, rememberSession: false);
  }

  Future<OtpDeliveryResult> resendVerificationCode(String email) async {
    if (normalizeAuthEmail(email).isEmpty) {
      throw const ValidationFailure('Email is required.');
    }
    return const OtpDeliveryResult(resendAfterSeconds: 30);
  }

  Future<OtpDeliveryResult> requestPasswordReset(String email) async {
    if (normalizeAuthEmail(email).isEmpty) {
      throw const ValidationFailure('Email is required.');
    }
    return const OtpDeliveryResult(resendAfterSeconds: 30);
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirm,
  }) async {
    final normalizedEmail = normalizeAuthEmail(email);
    if (normalizedEmail.isEmpty || !RegExp(r'^\d{6}$').hasMatch(code.trim())) {
      throw const ValidationFailure('Enter the 6-digit verification code.');
    }
    if (password != passwordConfirm) {
      throw const ValidationFailure('Passwords do not match.');
    }

    final accounts = await _store.loadAccounts();
    final index = accounts.indexWhere(
      (account) => normalizeAuthEmail(account.user.email) == normalizedEmail,
    );
    if (index < 0) return true;

    final updatedAccounts = [...accounts];
    updatedAccounts[index] = accounts[index].copyWith(
      passwordDigest: localAuthPasswordDigest(password),
    );
    await _store.saveAccounts(updatedAccounts);
    await _clearSession();
    return true;
  }

  Future<AuthUser> me() async {
    final session = _session ?? await restoreSavedSession();
    if (session == null) {
      throw const UnauthorizedFailure('No local user session.');
    }
    return session.user;
  }

  Future<AuthUser> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? gender,
    DateTime? birthDate,
  }) async {
    final currentUser = await me();
    final accounts = await _store.loadAccounts();
    final currentIndex = accounts.indexWhere(
      (account) => account.user.id == currentUser.id,
    );
    if (currentIndex < 0) {
      throw const UnauthorizedFailure('No local user session.');
    }

    final normalizedEmail = email == null ? null : normalizeAuthEmail(email);
    final normalizedUsername = username == null
        ? null
        : normalizeAuthUsername(username);

    if (normalizedEmail != null &&
        normalizedEmail != currentUser.email &&
        accounts.byEmail(normalizedEmail) != null) {
      throw const ValidationFailure('Email is already registered.');
    }

    if (phone != null) {
      final normalizedPhone = normalizeAuthPhone(phone);
      final currentPhone = normalizeAuthPhone(currentUser.phone ?? '');
      final isUsedByAnotherAccount =
          normalizedPhone.isNotEmpty &&
          normalizedPhone != currentPhone &&
          accounts.any(
            (account) =>
                account.user.id != currentUser.id &&
                normalizeAuthPhone(account.user.phone ?? '') == normalizedPhone,
          );
      if (isUsedByAnotherAccount) {
        throw const ValidationFailure('Phone number is already registered.');
      }
    }

    if (normalizedUsername != null &&
        normalizedUsername !=
            normalizeAuthUsername(currentUser.username ?? '') &&
        (!await isUsernameAvailable(normalizedUsername))) {
      throw const ValidationFailure('Username is not available.');
    }

    final usernameChanged =
        normalizedUsername != null &&
        normalizedUsername != currentUser.username;
    final updatedUser = currentUser.copyWith(
      email: normalizedEmail,
      firstName: firstName?.trim().isEmpty ?? true ? null : firstName?.trim(),
      lastName: lastName?.trim().isEmpty ?? true ? null : lastName?.trim(),
      username: normalizedUsername,
      phone: phone?.trim().isEmpty ?? true ? null : phone?.trim(),
      gender: gender?.trim().isEmpty ?? true ? null : gender?.trim(),
      birthDate: birthDate,
      usernameChangedAt: usernameChanged
          ? DateTime.now()
          : currentUser.usernameChangedAt,
    );

    final updatedAccounts = [...accounts];
    updatedAccounts[currentIndex] = accounts[currentIndex].copyWith(
      user: updatedUser,
    );
    await _store.saveAccounts(updatedAccounts);

    final updatedSession = AuthSession(user: updatedUser);
    _session = updatedSession;
    await _store.saveSession(updatedSession, _sessionExpiresAt);
    return updatedUser;
  }

  Future<AuthUser> updateProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty || fileName.trim().isEmpty) {
      throw const ValidationFailure('Could not update profile photo.');
    }

    final currentUser = await me();
    final accounts = await _store.loadAccounts();
    final currentIndex = accounts.indexWhere(
      (account) => account.user.id == currentUser.id,
    );
    if (currentIndex < 0) {
      throw const UnauthorizedFailure('No local user session.');
    }

    final updatedUser = currentUser.copyWith(
      avatarUrl: 'local-avatar://${Uri.encodeComponent(fileName.trim())}',
    );
    final updatedAccounts = [...accounts];
    updatedAccounts[currentIndex] = accounts[currentIndex].copyWith(
      user: updatedUser,
    );
    await _store.saveAccounts(updatedAccounts);

    final updatedSession = AuthSession(user: updatedUser);
    _session = updatedSession;
    await _store.saveSession(updatedSession, _sessionExpiresAt);
    return updatedUser;
  }

  Future<bool> logout() async {
    await _clearSession();
    return true;
  }

  Future<bool> deleteAccount(String password) async {
    final currentUser = await me();
    final accounts = await _store.loadAccounts();
    final currentIndex = accounts.indexWhere(
      (account) => account.user.id == currentUser.id,
    );
    if (currentIndex < 0 ||
        accounts[currentIndex].passwordDigest !=
            localAuthPasswordDigest(password)) {
      throw const ValidationFailure('The password is incorrect.');
    }

    final updatedAccounts = [...accounts]..removeAt(currentIndex);
    await _store.saveAccounts(updatedAccounts);
    await _clearSession();
    return true;
  }

  Future<AuthSession> _startSession(
    AuthUser user, {
    required bool rememberSession,
  }) async {
    final session = AuthSession(user: user);
    _session = session;
    _sessionExpiresAt = DateTime.now().add(
      rememberSession ? _rememberedSessionDuration : _temporarySessionDuration,
    );

    if (rememberSession) {
      await _store.saveSession(session, _sessionExpiresAt);
    } else {
      await _store.clearSession();
    }
    return session;
  }

  Future<void> _clearSession() async {
    _session = null;
    _sessionExpiresAt = null;
    await _store.clearSession();
  }

  bool _sessionHasExpired() {
    final expiresAt = _sessionExpiresAt;
    return expiresAt != null && !expiresAt.isAfter(DateTime.now());
  }
}
