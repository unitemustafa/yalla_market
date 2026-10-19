import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/notifications/push_notification_service.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test(
    'measurement flag isolates push and preserves normal mobile support',
    () {
      const measurement = bool.fromEnvironment('PERFORMANCE_TEST_BUILD');
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(pushNotificationsSupported, !kIsWeb && !measurement);
      }
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(pushNotificationsSupported, isFalse);
    },
  );
}
