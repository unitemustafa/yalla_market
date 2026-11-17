import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:yalla_market/features/auth/presentation/views/login_view.dart';
import 'package:yalla_market/yalla_market_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    initServiceLocator();
  });

  testWidgets('clean startup reaches a usable first screen', (tester) async {
    await tester.pumpWidget(const YallaMarketApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byKey(const ValueKey('splash_brand_logo')), findsOneWidget);

    // A successful first frame is insufficient: a permanently loading splash
    // must fail this test even when no Dart exception is thrown.
    for (var frame = 0; frame < 200; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(OnboardingView).evaluate().isNotEmpty ||
          find.byType(LoginView).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const ValueKey('splash_brand_logo')), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is OnboardingView || widget is LoginView,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
