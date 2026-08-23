import 'package:shared_preferences/shared_preferences.dart';

class PendingVerificationSnapshot {
  const PendingVerificationSnapshot({
    required this.email,
    required this.expiresAt,
  });

  final String email;
  final DateTime expiresAt;
}

class PendingVerificationStore {
  const PendingVerificationStore({DateTime Function()? now}) : _now = now;

  static const _emailKey = 'auth.pending_verification.email.v1';
  static const _expiryKey = 'auth.pending_verification.expires_at.v1';
  final DateTime Function()? _now;

  Future<void> save({required String email, DateTime? expiresAt}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final effectiveExpiry =
        expiresAt ?? _currentTime().add(const Duration(hours: 24));
    final preferences = await _preferencesOrNull();
    if (preferences == null) return;
    await preferences.setString(_emailKey, normalized);
    await preferences.setString(
      _expiryKey,
      effectiveExpiry.toUtc().toIso8601String(),
    );
  }

  Future<PendingVerificationSnapshot?> read() async {
    final preferences = await _preferencesOrNull();
    if (preferences == null) return null;
    final email = preferences.getString(_emailKey)?.trim().toLowerCase() ?? '';
    final expiresAt = DateTime.tryParse(
      preferences.getString(_expiryKey) ?? '',
    );
    if (email.isEmpty ||
        expiresAt == null ||
        !expiresAt.isAfter(_currentTime().toUtc())) {
      await clear();
      return null;
    }
    return PendingVerificationSnapshot(email: email, expiresAt: expiresAt);
  }

  Future<void> clear() async {
    final preferences = await _preferencesOrNull();
    if (preferences == null) return;
    await preferences.remove(_emailKey);
    await preferences.remove(_expiryKey);
  }

  DateTime _currentTime() => (_now ?? DateTime.now)();

  Future<SharedPreferences?> _preferencesOrNull() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // Pure Dart unit tests and unsupported platforms may not have a binding.
      return null;
    }
  }
}
