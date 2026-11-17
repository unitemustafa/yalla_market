import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/presentation/widgets/appbar/page_top_bar.dart';
import 'package:yalla_market/features/auth/presentation/widgets/auth_top_bar.dart';
import 'package:yalla_market/features/personalization/presentation/widgets/address_header_map_type.dart';
import 'package:yalla_market/features/personalization/presentation/widgets/address_location_map_widgets.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('headers omit back arrows and retain actions ($locale)', (
      tester,
    ) async {
      var closeCalls = 0;
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
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => actionCalls++,
                    ),
                  ],
                ),
                const AddressPageHeader(title: 'New address'),
                AuthTopBar(showClose: true, onClose: () => closeCalls++),
                PickerHeader(
                  title: 'Choose location',
                  onClose: () => closeCalls++,
                  onSearch: () => actionCalls++,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BackButton), findsNothing);
      for (final icon in [
        AppIcons.arrow_left_2,
        AppIcons.arrow_right_3,
        Icons.arrow_back_rounded,
        Icons.arrow_forward_rounded,
      ]) {
        expect(find.byIcon(icon), findsNothing);
      }
      expect(find.byIcon(Icons.close_rounded), findsNWidgets(2));
      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.tap(find.byIcon(AppIcons.search_normal));
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.tap(find.byKey(const ValueKey('map-picker-close')));
      expect(actionCalls, 2);
      expect(closeCalls, 2);
      expect(tester.takeException(), isNull);
    });
  }
}
