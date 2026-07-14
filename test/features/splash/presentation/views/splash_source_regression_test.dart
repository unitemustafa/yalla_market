import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restored sessions activate location preferences before navigation', () {
    final source = File(
      'lib/features/splash/presentation/views/splash_view.dart',
    ).readAsStringSync();
    final activateIndex = source.indexOf(
      'await locationCubit.activateUser(state.session!.user.id)',
    );
    final syncIndex = source.indexOf('locationCubit.syncCity(state.city)');
    final navigationIndex = source.indexOf(
      'Navigator.of(context).pushReplacementNamed(state.route)',
    );

    expect(activateIndex, greaterThanOrEqualTo(0));
    expect(syncIndex, greaterThan(activateIndex));
    expect(navigationIndex, greaterThan(syncIndex));
  });

  test('splash localizes the visible application name', () {
    final source = File(
      'lib/features/splash/presentation/views/splash_view.dart',
    ).readAsStringSync();

    expect(source, contains("context.tr('Yalla Market')"));
  });

  test('native launcher names are Arabic on Android and iOS', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final androidStrings = File(
      'android/app/src/main/res/values/strings.xml',
    ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();

    expect(androidManifest, contains('android:label="@string/app_name"'));
    expect(
      androidStrings,
      contains('<string name="app_name">يلا ماركت</string>'),
    );
    expect(iosInfo, contains('<string>يلا ماركت</string>'));
  });
}
