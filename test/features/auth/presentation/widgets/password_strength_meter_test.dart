import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/features/auth/presentation/widgets/password_strength_meter.dart';

void main() {
  setUp(() {
    AppLanguageController.instance.value = AppLanguage.english;
  });

  testWidgets('updates the visible password requirements', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PasswordStrengthMeter(controller: controller)),
      ),
    );

    expect(find.text('8+ characters'), findsOneWidget);
    expect(find.text('Upper & lowercase'), findsOneWidget);
    expect(find.text('Number & symbol'), findsOneWidget);
    expect(tester.takeException(), isNull);

    controller.text = 'abcdefgh';
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey(true)), findsOneWidget);

    controller.text = 'Abcdefgh';
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey(true)), findsNWidgets(2));

    controller.text = 'Abcdef1!';
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey(true)), findsNWidgets(3));
  });
}
