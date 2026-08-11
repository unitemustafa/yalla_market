import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/coordinators/app_session_coordinator.dart';

void main() {
  group('userSessionStorageKey', () {
    test('prefers the stable user id and trims it', () {
      expect(
        userSessionStorageKey(id: ' 42 ', email: 'user@example.com'),
        '42',
      );
    });

    test('falls back to email when the user id is absent', () {
      expect(
        userSessionStorageKey(id: ' ', email: ' user@example.com '),
        'user@example.com',
      );
    });

    test('returns null when neither identity is usable', () {
      expect(userSessionStorageKey(id: ' ', email: ''), isNull);
    });
  });
}
