import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_user.dart';
import 'package:yalla_market/features/personalization/presentation/controllers/user_profile_controller.dart';
import 'package:yalla_market/features/personalization/presentation/widgets/profile_completion_banner.dart';

void main() {
  tearDown(UserProfileController.instance.reset);

  testWidgets('shows progress for an incomplete social profile', (
    tester,
  ) async {
    UserProfileController.instance.updateFromAuthUser(
      const AuthUser(
        id: '1',
        email: 'social@example.com',
        firstName: 'Social',
        lastName: 'Customer',
        role: 'client',
        username: 'generated',
        profileUsernamePending: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ProfileCompletionBanner(onTap: () {}),
        ),
      ),
    );

    expect(find.text('Your profile is 29% complete'), findsOneWidget);
    expect(find.text('Complete now'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('is hidden after the profile is complete', (tester) async {
    UserProfileController.instance.updateFromAuthUser(
      AuthUser(
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
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ProfileCompletionBanner(onTap: () {}),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
