import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/features/auth/presentation/widgets/password_strength_meter.dart';

void main() {
  setUp(() {
    AppLanguageController.instance.value = AppLanguage.english;
  });

  testWidgets('updates the visible password requirements', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 600));
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
    expect(
      find.descendant(
        of: find.byType(PasswordStrengthMeter),
        matching: find.byType(Expanded),
      ),
      findsNWidgets(3),
    );
    final expandedSlots = tester.widgetList<Expanded>(
      find.descendant(
        of: find.byType(PasswordStrengthMeter),
        matching: find.byType(Expanded),
      ),
    );
    expect(expandedSlots.every((slot) => slot.child is Center), isTrue);
    expect(tester.takeException(), isNull);

    controller.text = 'abcdefgh';
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('8+ characters_true')), findsOneWidget);

    controller.text = 'Abcdefgh';
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('8+ characters_true')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('Upper & lowercase_true')),
      findsOneWidget,
    );

    controller.text = 'Abcdef1!';
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('8+ characters_true')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('Upper & lowercase_true')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('Number & symbol_true')), findsOneWidget);
  });

  testWidgets('shows translated Arabic requirements', (tester) async {
    AppLanguageController.instance.value = AppLanguage.arabic;
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppTranslations.supportedLocales,
        locale: const Locale('ar'),
        home: Scaffold(body: PasswordStrengthMeter(controller: controller)),
      ),
    );

    expect(find.text('8 حروف على الأقل'), findsOneWidget);
    expect(find.text('حرف كبير وصغير'), findsOneWidget);
    expect(find.text('رقم ورمز خاص'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to centered wrap on narrow width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PasswordStrengthMeter(controller: controller)),
      ),
    );

    final wrap = tester.widget<Wrap>(
      find.descendant(
        of: find.byType(PasswordStrengthMeter),
        matching: find.byType(Wrap),
      ),
    );
    expect(wrap.alignment, WrapAlignment.center);
    expect(wrap.runAlignment, WrapAlignment.center);
    expect(find.text('8+ characters'), findsOneWidget);
    expect(find.text('Upper & lowercase'), findsOneWidget);
    expect(find.text('Number & symbol'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
