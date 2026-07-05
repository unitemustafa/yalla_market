import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone editor does not contain demo OTP or WhatsApp flow', () {
    final source = File(
      'lib/features/personalization/presentation/views/profile/edit_profile_field_view.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('123456')));
    expect(source, isNot(contains('WhatsApp')));
    expect(source, isNot(contains('_ContactVerificationPanel')));
  });

  test('settings view does not load order history for profile stats', () {
    final source = File(
      'lib/features/personalization/presentation/views/settings/settings_view.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('OrderHistoryCubit')));
    expect(source, isNot(contains('OrderHistoryState')));
    expect(source, isNot(contains('loadOrders')));
    expect(source, isNot(contains('_ProfileStat')));
  });

  test('gold membership entry and disabled benefits page remain present', () {
    final profileSource = File(
      'lib/features/personalization/presentation/views/profile/profile_view.dart',
    ).readAsStringSync();
    final benefitsSource = File(
      'lib/features/personalization/presentation/views/profile/membership_benefits_view.dart',
    ).readAsStringSync();

    expect(profileSource, contains('Gold member'));
    expect(profileSource, contains('MembershipBenefitsView'));
    expect(profileSource, contains('isActive: false'));
    expect(benefitsSource, contains('Activate now'));
    expect(benefitsSource, contains('onPressed: null'));
  });
}
