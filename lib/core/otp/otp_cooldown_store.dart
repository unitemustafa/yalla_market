import 'package:shared_preferences/shared_preferences.dart';

class OtpPurpose {
  const OtpPurpose._();

  static const registration = 'registration';
  static const passwordReset = 'password_reset';
}

class OtpCooldownSnapshot {
  const OtpCooldownSnapshot({
    required this.remainingSeconds,
    required this.resendLevel,
    required this.resendAfterSeconds,
  });

  final int remainingSeconds;
  final int resendLevel;
  final int? resendAfterSeconds;
}

class OtpCooldownStore {
  const OtpCooldownStore();

  static const List<int> fallbackDurations = [30, 60, 120, 300];

  Future<OtpCooldownSnapshot?> read({
    required String purpose,
    required String identifier,
  }) async {
    final normalized = normalizeIdentifier(identifier);
    if (normalized.isEmpty) return null;

    final preferences = await SharedPreferences.getInstance();
    final prefix = _keyPrefix(purpose, normalized);
    final nextAllowedMillis = preferences.getInt('${prefix}_next_allowed_at');
    if (nextAllowedMillis == null) return null;

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final remainingMillis = nextAllowedMillis - nowMillis;
    if (remainingMillis <= 0) {
      await clear(purpose: purpose, identifier: normalized);
      return null;
    }

    return OtpCooldownSnapshot(
      remainingSeconds: (remainingMillis / 1000).ceil(),
      resendLevel: preferences.getInt('${prefix}_resend_level') ?? 0,
      resendAfterSeconds: preferences.getInt('${prefix}_resend_after_seconds'),
    );
  }

  Future<OtpCooldownSnapshot> save({
    required String purpose,
    required String identifier,
    required int seconds,
    int? resendLevel,
  }) async {
    final normalized = normalizeIdentifier(identifier);
    final safeSeconds = seconds < 1 ? 1 : seconds;
    final preferences = await SharedPreferences.getInstance();
    final prefix = _keyPrefix(purpose, normalized);
    final level = resendLevel ?? _nextLevel(preferences, prefix);
    final nextAllowedAt = DateTime.now().add(Duration(seconds: safeSeconds));

    await preferences.setInt(
      '${prefix}_next_allowed_at',
      nextAllowedAt.millisecondsSinceEpoch,
    );
    await preferences.setInt('${prefix}_resend_level', level);
    await preferences.setInt('${prefix}_resend_after_seconds', safeSeconds);

    return OtpCooldownSnapshot(
      remainingSeconds: safeSeconds,
      resendLevel: level,
      resendAfterSeconds: safeSeconds,
    );
  }

  Future<void> clear({
    required String purpose,
    required String identifier,
  }) async {
    final normalized = normalizeIdentifier(identifier);
    if (normalized.isEmpty) return;

    final preferences = await SharedPreferences.getInstance();
    final prefix = _keyPrefix(purpose, normalized);
    await preferences.remove('${prefix}_next_allowed_at');
    await preferences.remove('${prefix}_resend_level');
    await preferences.remove('${prefix}_resend_after_seconds');
  }

  String normalizeIdentifier(String value) => value.trim().toLowerCase();

  String formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _keyPrefix(String purpose, String identifier) {
    return 'otp_cooldown_${purpose}_$identifier';
  }

  int _nextLevel(SharedPreferences preferences, String prefix) {
    final currentLevel = preferences.getInt('${prefix}_resend_level') ?? 0;
    return (currentLevel + 1).clamp(0, fallbackDurations.length - 1).toInt();
  }
}
