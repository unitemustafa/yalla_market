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
    expect(AppPreferencesController.instance.safeModeEnabled, isFalse);
    expect(AppPreferencesController.instance.value.themeMode, ThemeMode.system);
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

  test('persists safe mode under the dedicated local key', () async {
    await AppPreferencesController.instance.loadSavedPreferences();
    await AppPreferencesController.instance.setSafeModeEnabled(true);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(AppPreferencesController.safeModeStorageKey),
      isTrue,
    );

    AppPreferencesController.instance.value = const AppPreferences();
    await AppPreferencesController.instance.loadSavedPreferences();
    expect(AppPreferencesController.instance.safeModeEnabled, isTrue);
  });
}
