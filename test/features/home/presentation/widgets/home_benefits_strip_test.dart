import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/features/home/presentation/widgets/home_benefits_strip.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'home benefits strip fits a narrow screen in ${locale.languageCode}',
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
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: const Scaffold(
                body: Center(
                  child: SizedBox(width: 320, child: HomeBenefitsStrip()),
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('home_benefits_strip')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('home_benefit_delivery')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('home_benefit_discount')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('home_benefit_payment')),
          findsOneWidget,
        );
        expect(
          find.text(locale.languageCode == 'ar' ? 'ادفع كاش' : 'Pay cash'),
          findsOneWidget,
        );
        final paymentLabel = tester.widget<Text>(
          find.text(locale.languageCode == 'ar' ? 'ادفع كاش' : 'Pay cash'),
        );
        expect(paymentLabel.style?.fontSize, AppFontSizes.micro);
        expect(paymentLabel.maxLines, 1);
        expect(paymentLabel.softWrap, isFalse);
        for (final richText in tester.widgetList<Text>(find.byType(Text))) {
          if (richText.textSpan != null) {
            expect(richText.maxLines, 1);
            expect(richText.softWrap, isFalse);
          }
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
