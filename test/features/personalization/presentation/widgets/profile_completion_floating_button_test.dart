import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_user.dart';
import 'package:yalla_market/features/personalization/presentation/controllers/user_profile_controller.dart';
import 'package:yalla_market/features/personalization/presentation/widgets/profile_completion_floating_button.dart';

void main() {
  tearDown(UserProfileController.instance.reset);

  testWidgets('shows circular progress and percentage for incomplete profile', (
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
      const MaterialApp(
        home: Scaffold(floatingActionButton: ProfileCompletionFloatingButton()),
      ),
    );

    expect(find.text('29%'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
  });

  testWidgets(
    'tapping button opens bottom sheet with missing fields and triggers callbacks',
    (tester) async {
      String? openedField;
      var continued = false;

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
            floatingActionButton: ProfileCompletionFloatingButton(
              onOpenField: (field) => openedField = field,
              onContinue: () => continued = true,
            ),
          ),
        ),
      );

      // Tap the floating button
      await tester.tap(find.byType(ProfileCompletionFloatingButton));
      await tester.pumpAndSettle();

      // Verify bottom sheet contents
      expect(find.text('Your profile is 29% complete'), findsOneWidget);
      expect(find.text('Missing details:'), findsOneWidget);
      expect(find.text('Phone number'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      expect(find.text('Complete now'), findsOneWidget);

      // Tap on Phone number field
      await tester.tap(find.text('Phone number'));
      await tester.pumpAndSettle();

      expect(openedField, 'phone');

      // Tap floating button again to test Complete now button
      await tester.tap(find.byType(ProfileCompletionFloatingButton));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Complete now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete now'));
      await tester.pumpAndSettle();

      expect(continued, isTrue);
    },
  );

  testWidgets('is hidden when profile is 100% complete', (tester) async {
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
      const MaterialApp(
        home: Scaffold(floatingActionButton: ProfileCompletionFloatingButton()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('100%'), findsNothing);
  });

  testWidgets('completion sheet scrolls on a compact screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    UserProfileController.instance.updateFromAuthUser(
      const AuthUser(
        id: '1',
        email: 'social@example.com',
        firstName: '',
        lastName: '',
        role: 'client',
        username: 'generated',
        profileUsernamePending: true,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(floatingActionButton: ProfileCompletionFloatingButton()),
      ),
    );
    await tester.tap(find.byType(ProfileCompletionFloatingButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Complete now'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('completion sheet remains centered on a tablet', (tester) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
      const MaterialApp(
        home: Scaffold(floatingActionButton: ProfileCompletionFloatingButton()),
      ),
    );
    await tester.tap(find.byType(ProfileCompletionFloatingButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final sheet = find.ancestor(
      of: find.text('Missing details:'),
      matching: find.byType(SingleChildScrollView),
    );
    expect(tester.getSize(sheet).width, lessThanOrEqualTo(640));
    expect(tester.getTopLeft(sheet).dx, greaterThan(150));
  });
}
