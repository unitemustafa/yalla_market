import 'dart:async';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/preferences/app_preferences_controller.dart';
import 'package:yalla_market/core/theme/app_theme.dart';
import 'package:yalla_market/core/theme/app_theme_toggle.dart';
import 'package:yalla_market/features/personalization/presentation/widgets/settings_page_widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferencesController.instance.value = const AppPreferences();
  });

  for (final reducedMotion in [false, true]) {
    testWidgets('toggles directly and preserves page state ($reducedMotion)', (
      tester,
    ) async {
      final contentKey = GlobalKey();
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ThemeProvider(
          initTheme: AppTheme.lightTheme,
          builder: (context, theme) => MaterialApp(
            navigatorKey: navigatorKey,
            theme: theme,
            themeAnimationDuration: Duration.zero,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reducedMotion),
              child: ThemeSwitchingArea(
                child: KeyedSubtree(key: contentKey, child: child!),
              ),
            ),
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Column(
              children: [
                _ProfileHeader(),
                TextField(key: Key('draft')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('draft')), 'Keep my draft');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      final fieldState = tester.state(find.byType(EditableText));
      expect(find.byIcon(AppIcons.moon), findsOneWidget);
      expect(find.byIcon(AppIcons.setting_2), findsOneWidget);

      Future<void> toggle() async {
        expect(
          tester
              .widget<IconButton>(
                find.descendant(
                  of: find.byType(AppThemeToggle),
                  matching: find.byType(IconButton),
                ),
              )
              .onPressed,
          isNotNull,
        );
        // toImage completes on the raster thread outside the fake test clock.
        await tester.runAsync(() async {
          final model = ThemeModelInheritedNotifier.of(
            tester.element(find.byType(AppThemeToggle)),
          );
          final captured = Completer<void>();
          void onCapture() {
            if (!captured.isCompleted) captured.complete();
          }

          model.addListener(onCapture);
          try {
            await tester.tap(find.byType(AppThemeToggle));
            await captured.future.timeout(const Duration(seconds: 5));
          } finally {
            model.removeListener(onCapture);
          }
        });
        await tester.pump(const Duration(milliseconds: 1));
        if (!reducedMotion) {
          expect(find.byType(ClipPath), findsWidgets);
          // Further taps during the reveal must not reverse the stored choice.
          await tester.tap(find.byType(AppThemeToggle), warnIfMissed: false);
        }
        await tester.pumpAndSettle();
        // Drain the completion callback registered in the raster capture zone.
        await tester.runAsync(() async {});
        await tester.pumpAndSettle();
      }

      await toggle();
      expect(
        Theme.of(tester.element(find.byType(AppThemeToggle))).brightness,
        Brightness.dark,
      );
      expect(find.byIcon(AppIcons.sun_1), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.state(find.byType(EditableText)), same(fieldState));
      expect(find.text('Keep my draft'), findsOneWidget);
      expect(navigatorKey.currentState!.canPop(), isTrue);
      final storage = await SharedPreferences.getInstance();
      expect(storage.getString('app.preferences.theme_mode'), 'dark');

      await toggle();
      expect(
        Theme.of(tester.element(find.byType(AppThemeToggle))).brightness,
        Brightness.light,
      );
      expect(find.byIcon(AppIcons.moon), findsOneWidget);
      expect(storage.getString('app.preferences.theme_mode'), 'light');
      expect(tester.state(find.byType(EditableText)), same(fieldState));
      expect(tester.takeException(), isNull);
    });
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) => SettingsProfileTopBar(
    isDark: Theme.of(context).brightness == Brightness.dark,
    onSettingsTap: () {},
  );
}
