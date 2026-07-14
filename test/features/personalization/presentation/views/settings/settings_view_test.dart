import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/preferences/app_preferences_controller.dart';
import 'package:yalla_market/features/personalization/presentation/views/settings/app_preferences_view.dart';
import 'package:yalla_market/features/personalization/presentation/views/settings/settings_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferencesController.instance.value = const AppPreferences();
  });

  testWidgets('settings keeps order entry without loading order history', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsView()));

    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('My Cart'), findsOneWidget);
    expect(find.text('My Addresses'), findsOneWidget);
    expect(find.text('Orders'), findsNothing);
    expect(find.text('-'), findsNothing);
  });

  testWidgets('settings fits a compact iPhone viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: SettingsView()));
    await tester.pump();

    expect(find.text('My Orders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings tooltip is translated in Arabic', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: AppTranslations.supportedLocales,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SettingsView(),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'تفضيلات التطبيق',
      ),
      findsOneWidget,
    );
  });

  testWidgets('app preferences shows readonly EGP currency', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppPreferencesView()));

    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('EGP'), findsOneWidget);
    expect(find.text('Egyptian Pound'), findsNothing);
  });

  testWidgets('app preferences switches use local controller state', (
    tester,
  ) async {
    await AppPreferencesController.instance.loadSavedPreferences();

    await tester.pumpWidget(const MaterialApp(home: AppPreferencesView()));

    expect(find.text('Mobile Notifications'), findsOneWidget);
    expect(find.text('Safe Mode'), findsOneWidget);
    expect(
      AppPreferencesController.instance.value.mobileNotificationsEnabled,
      isTrue,
    );
    expect(AppPreferencesController.instance.value.safeModeEnabled, isFalse);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(
      AppPreferencesController.instance.value.mobileNotificationsEnabled,
      isFalse,
    );
    expect(AppPreferencesController.instance.value.safeModeEnabled, isTrue);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(
        AppPreferencesController.mobileNotificationsStorageKey,
      ),
      isFalse,
    );
    expect(
      preferences.getBool(AppPreferencesController.safeModeStorageKey),
      isTrue,
    );
  });
}
