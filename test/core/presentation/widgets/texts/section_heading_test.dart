import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/presentation/widgets/texts/section_heading.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'View all is compact and directional in ${locale.languageCode}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: AppTranslations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: SectionHeading(title: 'Section', onPressed: () {}),
            ),
          ),
        );

        final label = locale.languageCode == 'ar' ? 'عرض الكل' : 'View all';
        expect(tester.widget<Text>(find.text(label)).style?.fontSize, 12);
        expect(
          find.byIcon(
            locale.languageCode == 'ar'
                ? AppIcons.arrow_left_2
                : AppIcons.arrow_right_3,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
