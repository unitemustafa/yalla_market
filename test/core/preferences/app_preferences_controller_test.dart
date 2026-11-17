import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/preferences/app_preferences_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferencesController.instance.value = const AppPreferences();
  });

  test('loads default local-only app preference values', () async {
    await AppPreferencesController.instance.loadSavedPreferences();

    expect(
      AppPreferencesController.instance.value.mobileNotificationsEnabled,
      isTrue,
    );
    expect(AppPreferencesController.instance.value.themeMode, ThemeMode.light);
  });

  test('invalid stored types do not block app startup', () async {
    SharedPreferences.setMockInitialValues({
      AppPreferencesController.mobileNotificationsStorageKey: 'invalid',
      'app.preferences.push_notifications': 12,
      'app.preferences.theme_mode': false,
    });

    await AppPreferencesController.instance.loadSavedPreferences();

    expect(AppPreferencesController.instance.value, const AppPreferences());
  });

  test('persists mobile notifications under the dedicated local key', () async {
    await AppPreferencesController.instance.loadSavedPreferences();
    await AppPreferencesController.instance.setMobileNotificationsEnabled(
      false,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(
        AppPreferencesController.mobileNotificationsStorageKey,
      ),
      isFalse,
    );

    AppPreferencesController.instance.value = const AppPreferences();
    await AppPreferencesController.instance.loadSavedPreferences();
    expect(
      AppPreferencesController.instance.mobileNotificationsEnabled,
      isFalse,
    );
  });

  for (final stored in ['system', 'invalid']) {
    test('loads light mode for legacy or unknown theme: $stored', () async {
      SharedPreferences.setMockInitialValues({
        'app.preferences.theme_mode': stored,
      });
      await AppPreferencesController.instance.loadSavedPreferences();
      expect(
        AppPreferencesController.instance.value.themeMode,
        ThemeMode.light,
      );
    });
  }

  test('persists and restores an explicit dark theme', () async {
    await AppPreferencesController.instance.setThemeMode(ThemeMode.dark);
    AppPreferencesController.instance.value = const AppPreferences();
    await AppPreferencesController.instance.loadSavedPreferences();
    expect(AppPreferencesController.instance.value.themeMode, ThemeMode.dark);
  });

  test(
    'ignores legacy safe-mode preferences without changing other values',
    () async {
      SharedPreferences.setMockInitialValues({
        'safe_search_history_mode_enabled': true,
        'app.preferences.safe_mode': true,
        AppPreferencesController.mobileNotificationsStorageKey: false,
      });

      await AppPreferencesController.instance.loadSavedPreferences();

      expect(
        AppPreferencesController.instance.mobileNotificationsEnabled,
        isFalse,
      );
      expect(
        AppPreferencesController.instance.value.themeMode,
        ThemeMode.light,
      );
    },
  );
}
