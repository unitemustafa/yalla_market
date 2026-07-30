import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';

void main() {
  testWidgets(
    'market types fit an iPhone SE width and overflow into a bottom sheet',
    (tester) async {
      String? selectedId = '1';
      final types = List.generate(
        6,
        (index) => StoreMarketTypeData(
          id: '${index + 1}',
          nameAr: 'تصنيف ${index + 1}',
          nameEn: 'Type ${index + 1}',
          image: 'assets/images/temporary_market_placeholder.webp',
          sortOrder: index,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppTranslations.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              padding: EdgeInsets.only(top: 20, bottom: 16),
              textScaler: TextScaler.linear(1.15),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: MarketTypeRail(
                  classificationName: 'المطاعم',
                  types: types,
                  selectedId: selectedId,
                  onSelected: (value) => selectedId = value,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('market_type_all')), findsNothing);
      expect(find.byKey(const ValueKey('market_type_4')), findsOneWidget);
      expect(find.byKey(const ValueKey('market_type_5')), findsNothing);
      expect(
        find.byKey(const ValueKey('market_type_view_all')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('market_type_1')));
      await tester.pump();
      expect(selectedId, isNull);

      await tester.tap(find.byKey(const ValueKey('market_type_view_all')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('market_type_all_sheet')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('market_type_sheet_5')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('market_type_sheet_5')));
      await tester.pumpAndSettle();

      expect(selectedId, '5');
      expect(tester.takeException(), isNull);
    },
  );
}
