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
  await configureAndroidDisplayMode();
  AppEnvironment.validate();
  initServiceLocator();
  await AppLanguageController.instance.loadSavedLanguage();
  await AppPreferencesController.instance.loadSavedPreferences();
  runApp(const YallaMarketApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeBackgroundServices());
  });
}

Future<void> _initializeFirebase() async {
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error\n$stackTrace');
  }
}

Future<void> _initializeBackgroundServices() async {
  await sl<PushNotificationService>().initialize();
  if (Firebase.apps.isNotEmpty) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      kReleaseMode,
    );
    if (kReleaseMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }
}
