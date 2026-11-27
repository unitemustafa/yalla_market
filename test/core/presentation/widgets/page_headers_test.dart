import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/presentation/widgets/appbar/page_top_bar.dart';
import 'package:yalla_market/features/auth/presentation/widgets/auth_top_bar.dart';
import 'package:yalla_market/features/personalization/presentation/widgets/address_header_map_type.dart';
import 'package:yalla_market/features/personalization/presentation/widgets/address_location_map_widgets.dart';

void main() {
  testWidgets(
    'PageTopBar uses the navigator fallback only when a route can pop',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const PageTopBar(title: 'Root'),
                Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                          body: PageTopBar(title: 'Pushed page'),
                        ),
                      ),
                    ),
                    child: const Text('Push page'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(AppIcons.arrow_left_2), findsNothing);
      await tester.tap(find.text('Push page'));
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.arrow_left_2), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.arrow_left_2));
      await tester.pumpAndSettle();
      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Pushed page'), findsNothing);
    },
  );

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('headers restore back actions and retain actions ($locale)', (
      tester,
    ) async {
      var backCalls = 0;
      var actionCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: Column(
              children: [
                PageTopBar(
                  title: 'Settings',
                  onBackPressed: () => backCalls++,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => actionCalls++,
                    ),
                  ],
                ),
                AddressPageHeader(
                  title: 'New address',
                  onBack: () => backCalls++,
                ),
                AuthTopBar(showBack: true, onBack: () => backCalls++),
                PickerHeader(
                  title: 'Choose location',
                  onClose: () => backCalls++,
                  onSearch: () => actionCalls++,
                ),
              ],
            ),
          ),
        ),
      );

      final backIcon = locale.languageCode == 'ar'
          ? AppIcons.arrow_right_3
          : AppIcons.arrow_left_2;
      expect(find.byIcon(backIcon), findsNWidgets(4));
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.tap(find.byIcon(AppIcons.search_normal));
      await tester.tap(find.byIcon(backIcon).at(0));
      await tester.tap(find.byIcon(backIcon).at(1));
      await tester.tap(find.byIcon(backIcon).at(2));
      await tester.tap(find.byKey(const ValueKey('map-picker-close')));
      expect(actionCalls, 2);
      expect(backCalls, 4);
      expect(tester.takeException(), isNull);
    });
  }
}
