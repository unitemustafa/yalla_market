import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('release readiness configuration', () {
    test(
      'Android release signing fails closed and production requires HTTPS',
      () {
        final buildFile = File(
          'android/app/build.gradle.kts',
        ).readAsStringSync();
        final mainManifest = File(
          'android/app/src/main/AndroidManifest.xml',
        ).readAsStringSync();
        final debugManifest = File(
          'android/app/src/debug/AndroidManifest.xml',
        ).readAsStringSync();

        expect(
          buildFile,
          contains('requestedReleaseBuild && !hasReleaseKeystore'),
        );
        expect(
          buildFile,
          isNot(contains('if (hasReleaseKeystore) "release" else "debug"')),
        );
        expect(mainManifest, contains('android:usesCleartextTraffic="false"'));
        expect(mainManifest, contains('android:allowBackup="false"'));
        expect(debugManifest, contains('android:usesCleartextTraffic="true"'));
      },
    );

    test('Crashlytics captures uncaught errors only in release mode', () {
      final mainFile = File('lib/main.dart').readAsStringSync();
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final settings = File('android/settings.gradle.kts').readAsStringSync();

      expect(pubspec, contains('firebase_crashlytics:'));
      expect(settings, contains('com.google.firebase.crashlytics'));
      expect(mainFile, contains('setCrashlyticsCollectionEnabled'));
      expect(mainFile, contains('kReleaseMode'));
      expect(mainFile, contains('recordFlutterFatalError'));
      expect(mainFile, contains('PlatformDispatcher.instance.onError'));
    });

    test('network status is event-driven and refreshes on app resume', () {
      final controller = File(
        'lib/core/connectivity/internet_status_controller.dart',
      ).readAsStringSync();
      final banner = File(
        'lib/core/presentation/widgets/offline_connection_banner.dart',
      ).readAsStringSync();

      expect(controller, isNot(contains('Timer.periodic')));
      expect(controller, contains('onConnectivityChanged.listen'));
      expect(banner, contains('WidgetsBindingObserver'));
      expect(banner, contains('AppLifecycleState.resumed'));
      expect(banner, contains('_internetStatusController.refresh()'));
    });

    test('iOS includes pods, APNs entitlements, and required usage text', () {
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();

      expect(File('ios/Podfile').existsSync(), isTrue);
      expect(File('ios/Runner/RunnerDebug.entitlements').existsSync(), isTrue);
      expect(
        File('ios/Runner/RunnerRelease.entitlements').existsSync(),
        isTrue,
      );
      expect(infoPlist, contains('NSPhotoLibraryUsageDescription'));
      expect(infoPlist, contains('remote-notification'));
      expect(project, contains('Runner/RunnerDebug.entitlements'));
      expect(project, contains('Runner/RunnerRelease.entitlements'));
    });
  });
}
