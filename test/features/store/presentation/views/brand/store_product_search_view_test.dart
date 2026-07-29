import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/presentation/widgets/texts/green_currency_price.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/presentation/views/brand/store_product_search_view.dart';

void main() {
  testWidgets(
    'store search opens focused and filters only this store products',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: StoreProductSearchView(market: _market),
          ),
        ),
      );
      await tester.pump();

      final field = find.byKey(const ValueKey('store_search_page_field'));
      expect(field, findsOneWidget);
      final results = find.byKey(const ValueKey('store_search_results'));
      expect(
        find.descendant(of: results, matching: find.text('Pasta')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: results, matching: find.text('Cola')),
        findsOneWidget,
      );
      expect(tester.testTextInput.isVisible, isTrue);
      expect(find.byType(GreenCurrencyPrice), findsNWidgets(2));

      await tester.enterText(
        find.descendant(of: field, matching: find.byType(TextField)),
        'Pasta',
      );
      await tester.pump();

      expect(
        find.descendant(of: results, matching: find.text('Pasta')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: results, matching: find.text('Cola')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('store search localizes its empty state and hint in Arabic', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppTranslations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StoreProductSearchView(market: _market),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ابحث في القائمة...'), findsOneWidget);

    final field = find.byKey(const ValueKey('store_search_page_field'));
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      'غير موجود',
    );
    await tester.pump();

    expect(find.text('مفيش منتجات'), findsOneWidget);
    expect(find.text('جرّب اسم منتج آخر.'), findsOneWidget);
  });
}

final _market = StoreMarketData(
  id: 'market',
  name: 'Store',
  branch: '',
  status: 'active',
  classificationId: 'food',
  products: const [
    ProductData(
      id: 'pasta',
      image: AppAssets.defaultProduct,
      title: 'Pasta',
      brand: 'Store',
      price: '120',
      oldPrice: null,
      discount: '',
      tags: [],
      description: 'Creamy chicken pasta',
    ),
    ProductData(
      id: 'cola',
      image: AppAssets.defaultProduct,
      title: 'Cola',
      brand: 'Store',
      price: '30',
      oldPrice: null,
      discount: '',
      tags: [],
      description: 'Cold drink',
    ),
  ],
  image: AppAssets.defaultStore,
  coverImage: AppAssets.emptyStoreLight,
  accentColorValue: 0xFF013C7E,
);
