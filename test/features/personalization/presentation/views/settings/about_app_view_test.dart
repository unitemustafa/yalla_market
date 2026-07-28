import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/personalization/presentation/views/settings/about_app_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const packageInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/package_info',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (_) async {
          return <String, dynamic>{
            'appName': 'Yalla Market',
            'packageName': 'com.yallamarket.app',
            'version': '1.0.16',
            'buildNumber': '4030',
            'buildSignature': '',
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
  });

  testWidgets('FAQ answers start collapsed and expand when tapped', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AboutAppView()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Frequently asked questions').first);
    await tester.pumpAndSettle();

    const answer =
        'Choose your market and products, add the delivery address, then confirm your order from the cart.';
    expect(find.text(answer), findsNothing);

    await tester.tap(find.text('How do I place an order?'));
    await tester.pumpAndSettle();

    expect(find.text(answer), findsOneWidget);
  });
}
