import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/otp/pending_verification_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists and restores an unexpired pending verification', () async {
    final now = DateTime.utc(2026, 8, 24, 10);
    final store = PendingVerificationStore(now: () => now);
    final expiresAt = now.add(const Duration(hours: 24));

    await store.save(email: ' Pending@Example.com ', expiresAt: expiresAt);
    final restored = await store.read();

    expect(restored?.email, 'pending@example.com');
    expect(restored?.expiresAt, expiresAt);
  });

  test('expired pending verification is cleared', () async {
    var now = DateTime.utc(2026, 8, 24, 10);
    final store = PendingVerificationStore(now: () => now);
    await store.save(
      email: 'pending@example.com',
      expiresAt: now.add(const Duration(minutes: 1)),
    );

    now = now.add(const Duration(minutes: 2));

    expect(await store.read(), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), isEmpty);
  });
}
