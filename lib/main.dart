import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/config/app_environment.dart';
import 'core/di/service_locator.dart';
import 'core/localization/app_language_controller.dart';
import 'core/preferences/app_preferences_controller.dart';
import 'core/notifications/push_notification_service.dart';
import 'yalla_market_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.validate();
  initServiceLocator();
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
  await AppLanguageController.instance.loadSavedLanguage();
  await AppPreferencesController.instance.loadSavedPreferences();
  runApp(const YallaMarketApp());
}
