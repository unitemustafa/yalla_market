import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_user.dart';
import 'package:yalla_market/features/home/data/repositories/region_hint_preferences_repository.dart';
import 'package:yalla_market/features/home/domain/usecases/region_hint_usecases.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final now = DateTime.utc(2026, 9, 29);

  test('new account sees hint once after either dismissal action', () async {
    final useCases = RegionHintUseCases(RegionHintPreferencesRepository());

    final initial = await useCases.shouldShow(
      userId: 'new-user',
      dateJoined: now.subtract(const Duration(days: 1)),
      now: now,
    );
    expect(
      initial.when(success: (show) => show, failure: (_) => false),
      isTrue,
    );

    await useCases.markSeen('new-user');
    final afterDismissal = await useCases.shouldShow(
      userId: 'new-user',
      dateJoined: now.subtract(const Duration(days: 1)),
      now: now,
    );
    expect(
      afterDismissal.when(success: (show) => show, failure: (_) => true),
      isFalse,
    );

    final otherUser = await useCases.shouldShow(
      userId: 'another-user',
      dateJoined: now,
      now: now,
    );
    expect(
      otherUser.when(success: (show) => show, failure: (_) => false),
      isTrue,
    );
  });

  test('existing or undated accounts do not see hint', () async {
    final useCases = RegionHintUseCases(RegionHintPreferencesRepository());
    for (final dateJoined in <DateTime?>[
      now.subtract(const Duration(days: 8)),
      null,
    ]) {
      final result = await useCases.shouldShow(
        userId: 'existing-user',
        dateJoined: dateJoined,
        now: now,
      );
      expect(
        result.when(success: (show) => show, failure: (_) => true),
        isFalse,
      );
    }
  });

  test('account creation date survives auth cache serialization', () {
    final user = AuthUser.fromJson({
      'id': '42',
      'email': 'new@example.com',
      'first_name': 'New',
      'last_name': 'User',
      'role': 'CUSTOMER',
      'date_joined': '2026-09-28T11:00:00Z',
    });

    expect(user.dateJoined, DateTime.utc(2026, 9, 28, 11));
    expect(
      AuthUser.fromJson(user.toJson()).dateJoined,
      DateTime.utc(2026, 9, 28, 11),
    );
  });
}
