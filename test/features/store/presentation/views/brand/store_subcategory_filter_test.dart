import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/offers/domain/entities/offer_data.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_store_sections.dart';

void main() {
  testWidgets('subcategory rail omits All and selects the first category', (
    tester,
  ) async {
    String? selectedId;
    const categories = [
      StoreSubcategoryData(id: '10', nameAr: 'وجبات', nameEn: 'Meals'),
      StoreSubcategoryData(id: '20', nameAr: 'مشروبات', nameEn: 'Drinks'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoreSubcategoryRail(
            categories: categories,
            selectedId: selectedId,
            languageCode: 'ar',
            categoryDescription: null,
            onSelected: (value) => selectedId = value,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('store_subcategory_all')), findsNothing);
    expect(find.text('وجبات'), findsOneWidget);
    expect(find.text('مشروبات'), findsOneWidget);

    final firstContainer = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('store_subcategory_10')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final firstBorder = (firstContainer.decoration! as BoxDecoration).border!;
    expect((firstBorder as Border).bottom.color, isNot(Colors.transparent));

    await tester.tap(find.byKey(const ValueKey('store_subcategory_20')));
    expect(selectedId, '20');
  });

  test(
    'All keeps inactive-category products and a category filters locally',
    () {
      final products = [
        ProductData.fromJson({'id': 1, 'name': 'Water', 'subcategory_id': 10}),
        ProductData.fromJson({
          'id': 2,
          'name': 'Hidden legacy product',
          'subcategory_id': 99,
        }),
      ];

      expect(productsForStoreSubcategory(products, null), hasLength(2));
      expect(
        productsForStoreSubcategory(products, '10').map((item) => item.id),
        ['1'],
      );
      expect(productsForStoreSubcategory(products, '20'), isEmpty);
    },
  );

  test('store search filters category markets by name or branch', () {
    const stores = [
      StoreMarketData(
        id: '1',
        name: 'البركة',
        branch: 'المنصورة',
        status: 'active',
        classificationId: 'furniture',
        products: [],
        image: '',
        accentColorValue: 0xFF013C7E,
      ),
      StoreMarketData(
        id: '2',
        name: 'النور',
        branch: 'القاهرة',
        status: 'active',
        classificationId: 'furniture',
        products: [],
        image: '',
        accentColorValue: 0xFF013C7E,
      ),
    ];

    expect(storesMatchingQuery(stores, 'البركة').map((store) => store.id), [
      '1',
    ]);
    expect(storesMatchingQuery(stores, 'القاهرة').map((store) => store.id), [
      '2',
    ]);
    expect(storesMatchingQuery(stores, ''), stores);
  });

  test('market type filters stores independently from internal categories', () {
    const stores = [
      StoreMarketData(
        id: '1',
        name: 'Burger House',
        branch: '',
        status: 'active',
        classificationId: 'restaurants',
        marketTypeIds: ['burger', 'sandwiches'],
        products: [],
        image: '',
        accentColorValue: 0xFF013C7E,
      ),
      StoreMarketData(
        id: '2',
        name: 'Eastern Grill',
        branch: '',
        status: 'active',
        classificationId: 'restaurants',
        marketTypeIds: ['grills', 'eastern'],
        products: [],
        image: '',
        accentColorValue: 0xFF013C7E,
      ),
    ];

    expect(storesMatchingType(stores, null), stores);
    expect(storesMatchingType(stores, 'burger').map((store) => store.id), [
      '1',
    ]);
    expect(storesMatchingType(stores, 'eastern').map((store) => store.id), [
      '2',
    ]);
    expect(storesMatchingType(stores, 'pizza'), isEmpty);
  });

  test(
    'offers are scoped to every participating market and classification',
    () {
      final singleMarket = OfferData.fromJson({
        'id': 1,
        'title': 'Single',
        'market': {'id': 10, 'classification_id': 100},
        'products': const [],
      });
      final multiMarket = OfferData.fromJson({
        'id': 2,
        'title': 'Package',
        'type': 'package',
        'markets': [
          {'id': 10, 'classification_id': 100},
          {'id': 20, 'classification_id': 200},
        ],
        'products': const [],
      });
      final announcement = OfferData.fromJson({
        'id': 3,
        'title': 'Announcement',
        'type': 'announcement',
        'products': const [],
      });
      final offers = [singleMarket, multiMarket, announcement, multiMarket];

      expect(offersForMarket(offers, '10').map((offer) => offer.id), [
        '1',
        '2',
      ]);
      expect(offersForMarket(offers, '20').map((offer) => offer.id), ['2']);
      expect(offersForClassification(offers, '100').map((offer) => offer.id), [
        '1',
        '2',
      ]);
      expect(offersForClassification(offers, '200').map((offer) => offer.id), [
        '2',
      ]);
      expect(offersForClassification(offers, '300'), isEmpty);
    },
  );

  test('a product assigned to two subcategories appears in both', () {
    final product = ProductData.fromJson({
      'id': 3,
      'name': 'Combo',
      'subcategories': [
        {'id': 10, 'name_ar': 'سندوتشات'},
        {'id': 20, 'name_ar': 'عصير'},
      ],
    });

    expect(productsForStoreSubcategory([product], '10'), [product]);
    expect(productsForStoreSubcategory([product], '20'), [product]);
  });
}
