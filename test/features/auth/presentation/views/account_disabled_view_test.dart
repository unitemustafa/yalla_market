import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/core/session/account_restored_notifier.dart';
import 'package:yalla_market/features/auth/presentation/views/account_disabled_view.dart';

void main() {
  setUp(AccountRestoredNotifier.instance.reset);
  tearDown(AccountRestoredNotifier.instance.reset);

  testWidgets('restoration updates disabled screen without automatic login', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const AccountDisabledView(),
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('login-screen')),
        },
      ),
    );

    AccountRestoredNotifier.instance.markRestored();
    await tester.pump();

    expect(find.text(accountRestoredViewMessage), findsOneWidget);
    expect(find.text('login-screen'), findsNothing);

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('login-screen'), findsOneWidget);
  });
}
