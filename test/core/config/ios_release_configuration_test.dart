import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/firebase_options.dart';

void main() {
  test('iOS deployment targets satisfy the installed Firebase minimum', () {
    final podfile = File('ios/Podfile').readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final podsTarget = RegExp(
      r"platform\s*:ios,\s*'([0-9.]+)'",
    ).firstMatch(podfile);
    expect(podsTarget, isNotNull);
    expect(double.parse(podsTarget!.group(1)!), greaterThanOrEqualTo(15));
    final targets = RegExp(
      r'IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([0-9.]+);',
    ).allMatches(project);
    expect(targets, isNotEmpty);
    for (final target in targets) {
      expect(double.parse(target.group(1)!), greaterThanOrEqualTo(15));
    }
  });

  test('both signing configurations enable secure session storage', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    for (final mode in ['Debug', 'Release']) {
      final path = 'Runner/Runner$mode.entitlements';
      expect(project, contains('CODE_SIGN_ENTITLEMENTS = $path;'));
      final entitlements = File('ios/$path').readAsStringSync();
      expect(entitlements, contains('<key>keychain-access-groups</key>'));
    }
    expect(project, contains('com.apple.Keychain'));
  });

  test('Firebase configuration is included in Runner resources', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(project, contains('path = "GoogleService-Info.plist"'));
    final resources = project.substring(
      project.indexOf('/* Begin PBXResourcesBuildPhase section */'),
      project.indexOf('/* End PBXResourcesBuildPhase section */'),
    );
    expect(resources, contains('GoogleService-Info.plist in Resources'));
  });

  test('Xcode and Firebase agree on the iOS app identity', () {
    const bundleId = 'com.yallamarket.app.com';
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final bundleIds = RegExp(
      r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);',
    ).allMatches(project).map((match) => match.group(1));
    expect(
      bundleIds,
      unorderedEquals([
        bundleId,
        bundleId,
        bundleId,
        ...List.filled(3, '$bundleId.RunnerTests'),
      ]),
    );

    final firebase = jsonDecode(File('firebase.json').readAsStringSync());
    final appIds =
        firebase['flutter']['platforms']['dart']['lib/firebase_options.dart']['configurations'];
    expect(DefaultFirebaseOptions.ios.iosBundleId, bundleId);
    expect(DefaultFirebaseOptions.ios.appId, appIds['ios']);
  });
}
