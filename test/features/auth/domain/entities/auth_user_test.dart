import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_user.dart';

void main() {
  test('incomplete social profile reports deterministic progress', () {
    const user = AuthUser(
      id: '1',
      email: 'social@example.com',
      firstName: 'Social',
      lastName: 'Customer',
      role: 'client',
      username: 'yalla_generated',
      profileUsernamePending: true,
    );

    expect(user.profileCompletionPercent, 29);
    expect(user.missingProfileFields, [
      'username',
      'phone',
      'city',
      'gender',
      'birth_date',
    ]);
    expect(user.isProfileComplete, isFalse);
  });

  test('completed profile reaches one hundred percent', () {
    final user = AuthUser(
      id: '1',
      email: 'social@example.com',
      firstName: 'Social',
      lastName: 'Customer',
      role: 'client',
      username: 'social.customer',
      phone: '+201001234567',
      city: 'Cairo',
      gender: 'male',
      birthDate: DateTime(1995, 4, 12),
    );

    expect(user.profileCompletionPercent, 100);
    expect(user.missingProfileFields, isEmpty);
    expect(user.isProfileComplete, isTrue);
  });

  test('server profile flags are parsed and cached', () {
    final user = AuthUser.fromJson({
      'id': 1,
      'email': 'social@example.com',
      'first_name': 'Social',
      'last_name': 'Customer',
      'role': 'client',
      'username': 'yalla_generated',
      'phone': null,
      'profile_username_pending': true,
    });

    expect(user.profileUsernamePending, isTrue);
    expect(user.toJson()['profileUsernamePending'], isTrue);
  });
}
