import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';

void main() {
  testWidgets(
    'market types keep Arabic content in an English app and fit a small width',
    (tester) async {
      String? selectedId;
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
          locale: const Locale('en'),
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
      expect(find.text('تصنيف 1'), findsNWidgets(2));
      expect(find.text('Type 1'), findsNothing);
      expect(find.text('View all'), findsOneWidget);
      expect(find.byKey(const ValueKey('market_type_4')), findsOneWidget);
      expect(find.byKey(const ValueKey('market_type_5')), findsNothing);
      expect(
        find.byKey(const ValueKey('market_type_view_all')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('market_type_1')));
      await tester.pump();
      expect(selectedId, '1');

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

  testWidgets('long market type names fit rail and sheet with enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const name = 'المطاعم والمأكولات الشرقية والمشويات والحلويات';
    final types = List.generate(
      6,
      (index) => StoreMarketTypeData(
        id: '$index',
        nameAr: name,
        nameEn: 'Long market category $index',
        image: AppAssets.defaultCategory,
        sortOrder: index,
      ),
    );
    String? selectedId;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: MarketTypeRail(
                  types: types,
                  selectedId: selectedId,
                  onSelected: (id) => setState(() => selectedId = id),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final card = find.byKey(const ValueKey('market_type_0'));
    final label = find.descendant(of: card, matching: find.text(name));
    expect(tester.widget<Text>(label).maxLines, 2);
    expect(tester.getSize(card).height, greaterThan(120));
    final heading = find.byKey(const ValueKey('selected_market_type_title'));
    expect(tester.widget<Text>(heading).data, name);
    expect(
      tester.renderObject<RenderParagraph>(heading).didExceedMaxLines,
      isFalse,
    );
    expect(tester.takeException(), isNull);

    final viewAll = find.byKey(const ValueKey('market_type_view_all'));
    await tester.scrollUntilVisible(
      viewAll,
      150,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('market_type_rail')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(viewAll);
    await tester.pumpAndSettle();
    final sheetCard = find.byKey(const ValueKey('market_type_sheet_0'));
    final sheetLabel = find.descendant(
      of: sheetCard,
      matching: find.text(name),
    );
    expect(tester.widget<Text>(sheetLabel).maxLines, 2);
    expect(tester.getSize(sheetCard).height, greaterThan(120));
    expect(tester.takeException(), isNull);
    await tester.tap(sheetCard);
    await tester.pumpAndSettle();
    expect(selectedId, '0');
    expect(tester.takeException(), isNull);
  });
}
