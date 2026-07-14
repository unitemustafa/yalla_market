import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  const AppPreferences({
    this.mobileNotificationsEnabled = true,
    this.safeModeEnabled = false,
    this.themeMode = ThemeMode.system,
  });

  final bool mobileNotificationsEnabled;

  // Safe Mode prevents future search queries from being persisted in search
  // history. Search integration will be implemented in the Search phase.
  final bool safeModeEnabled;
  final ThemeMode themeMode;

  bool get pushNotifications => mobileNotificationsEnabled;
  bool get safeMode => safeModeEnabled;

  AppPreferences copyWith({
    bool? mobileNotificationsEnabled,
    bool? safeModeEnabled,
    ThemeMode? themeMode,
  }) {
    return AppPreferences(
      mobileNotificationsEnabled:
          mobileNotificationsEnabled ?? this.mobileNotificationsEnabled,
      safeModeEnabled: safeModeEnabled ?? this.safeModeEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppPreferences &&
        other.mobileNotificationsEnabled == mobileNotificationsEnabled &&
        other.safeModeEnabled == safeModeEnabled &&
        other.themeMode == themeMode;
  }

  @override
  int get hashCode =>
      Object.hash(mobileNotificationsEnabled, safeModeEnabled, themeMode);
}

class AppPreferencesController extends ValueNotifier<AppPreferences> {
  AppPreferencesController._() : super(const AppPreferences());

  static final AppPreferencesController instance = AppPreferencesController._();

  static const String mobileNotificationsStorageKey =
      'mobile_notifications_enabled';
  static const String safeModeStorageKey = 'safe_search_history_mode_enabled';
  static const String _themeModeKey = 'app.preferences.theme_mode';
  static const String _legacyPushNotificationsKey =
      'app.preferences.push_notifications';
  static const String _legacySafeModeKey = 'app.preferences.safe_mode';

  bool get mobileNotificationsEnabled => value.mobileNotificationsEnabled;

  bool get safeModeEnabled => value.safeModeEnabled;

  Future<void> loadSavedPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    value = AppPreferences(
      mobileNotificationsEnabled:
          preferences.getBool(mobileNotificationsStorageKey) ??
          preferences.getBool(_legacyPushNotificationsKey) ??
          true,
      safeModeEnabled:
          preferences.getBool(safeModeStorageKey) ??
          preferences.getBool(_legacySafeModeKey) ??
          false,
      themeMode: _themeModeFromStorage(preferences.getString(_themeModeKey)),
    );
  }

  Future<void> setMobileNotificationsEnabled(bool enabled) {
    return _setPreference(
      key: mobileNotificationsStorageKey,
      value: enabled,
      nextPreferences: value.copyWith(mobileNotificationsEnabled: enabled),
    );
  }

  Future<void> setPushNotifications(bool enabled) {
    return setMobileNotificationsEnabled(enabled);
  }

  Future<void> setSafeModeEnabled(bool enabled) {
    return _setPreference(
      key: safeModeStorageKey,
      value: enabled,
      nextPreferences: value.copyWith(safeModeEnabled: enabled),
    );
  }

  Future<void> setSafeMode(bool enabled) {
    return setSafeModeEnabled(enabled);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final nextPreferences = value.copyWith(themeMode: themeMode);
    if (value == nextPreferences) return;

    value = nextPreferences;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, themeMode.name);
  }

  Future<void> _setPreference({
    required String key,
    required bool value,
    required AppPreferences nextPreferences,
  }) async {
    if (this.value == nextPreferences) return;

    this.value = nextPreferences;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }

  ThemeMode _themeModeFromStorage(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
