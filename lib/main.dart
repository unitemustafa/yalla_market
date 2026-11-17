import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/config/app_environment.dart';
import 'app/di/service_locator.dart';
import 'core/localization/app_language_controller.dart';
import 'core/preferences/app_preferences_controller.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/platform/android_display_mode.dart';
import 'yalla_market_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  _configureCrashlytics();
  try {
    await configureAndroidDisplayMode().timeout(const Duration(seconds: 1));
  } catch (_) {
    // The Flutter viewport also handles devices ignoring portrait requests.
  }
  AppEnvironment.validate();
  initServiceLocator();
  await Future.wait([
    AppLanguageController.instance.loadSavedLanguage(),
    AppPreferencesController.instance.loadSavedPreferences(),
  ]);
  runApp(const YallaMarketApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeBackgroundServices());
  });
}

Future<void> _initializeFirebase() async {
  // Isolated measurement packages must never contact production Firebase.
  if (const bool.fromEnvironment('PERFORMANCE_TEST_BUILD')) return;
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 4));
    }
  } catch (_) {
    debugPrint('Firebase initialization unavailable during startup.');
  }
}

Future<void> _initializeBackgroundServices() async {
  if (const bool.fromEnvironment('PERFORMANCE_TEST_BUILD')) return;
  try {
    await sl<PushNotificationService>().initialize().timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {
    debugPrint('Push notification initialization unavailable during startup.');
  } finally {
    // Firebase may have finished after its startup deadline.
    _configureCrashlytics();
  }
}

void _configureCrashlytics() {
  if (const bool.fromEnvironment('PERFORMANCE_TEST_BUILD')) return;
  if (Firebase.apps.isEmpty) return;
  final crashlytics = FirebaseCrashlytics.instance;
  unawaited(_setCrashlyticsCollection(crashlytics, kReleaseMode));
  if (!kReleaseMode) return;
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(crashlytics.recordError(error, stack, fatal: true));
    return true;
  };
}

Future<void> _setCrashlyticsCollection(
  FirebaseCrashlytics crashlytics,
  bool enabled,
) async {
  try {
    await crashlytics
        .setCrashlyticsCollectionEnabled(enabled)
        .timeout(const Duration(seconds: 2));
  } catch (_) {
    debugPrint('Crash reporting initialization unavailable during startup.');
  }
}
