import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/otp/otp_cooldown_store.dart';

void main() {
  const store = OtpCooldownStore();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('restores remaining cooldown after store is recreated', () async {
    await store.save(
      purpose: OtpPurpose.passwordReset,
      identifier: 'User@Example.com',
      seconds: 30,
    );

    const recreatedStore = OtpCooldownStore();
    final snapshot = await recreatedStore.read(
      purpose: OtpPurpose.passwordReset,
      identifier: 'user@example.com',
    );

    expect(snapshot, isNotNull);
    expect(snapshot!.remainingSeconds, inInclusiveRange(1, 30));
  });

  test('registration and password reset cooldowns are separate', () async {
    await store.save(
      purpose: OtpPurpose.registration,
      identifier: 'm@example.com',
      seconds: 30,
    );

    final registration = await store.read(
      purpose: OtpPurpose.registration,
      identifier: 'm@example.com',
    );
    final passwordReset = await store.read(
      purpose: OtpPurpose.passwordReset,
      identifier: 'm@example.com',
    );

    expect(registration, isNotNull);
    expect(passwordReset, isNull);
  });

  test('different identifiers have separate cooldowns', () async {
    await store.save(
      purpose: OtpPurpose.passwordReset,
      identifier: 'a@example.com',
      seconds: 30,
    );

    final first = await store.read(
      purpose: OtpPurpose.passwordReset,
      identifier: 'a@example.com',
    );
    final second = await store.read(
      purpose: OtpPurpose.passwordReset,
      identifier: 'b@example.com',
    );

    expect(first, isNotNull);
    expect(second, isNull);
  });

  test('clear removes only the requested cooldown', () async {
    await store.save(
      purpose: OtpPurpose.registration,
      identifier: 'm@example.com',
      seconds: 30,
    );
    await store.save(
      purpose: OtpPurpose.passwordReset,
      identifier: 'm@example.com',
      seconds: 30,
    );

    await store.clear(
      purpose: OtpPurpose.passwordReset,
      identifier: 'm@example.com',
    );

    expect(
      await store.read(
        purpose: OtpPurpose.registration,
        identifier: 'm@example.com',
      ),
      isNotNull,
    );
    expect(
      await store.read(
        purpose: OtpPurpose.passwordReset,
        identifier: 'm@example.com',
      ),
      isNull,
    );
  });
}
