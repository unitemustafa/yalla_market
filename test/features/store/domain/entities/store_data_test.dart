import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';

void main() {
  group('Store data mapping', () {
    test('maps classification and market payloads from backend', () {
      final classification = StoreClassificationData.fromJson({
        'id': 7,
        'name': 'Supermarket',
        'market_count': 2,
        'classification_type': 'featured',
        'market_types': [
          {
            'id': 11,
            'name_ar': 'برجر',
            'name_en': 'Burger',
            'image': '/media/market-types/burger.webp',
            'sort_order': 1,
          },
        ],
        'products': [_marketProduct()],
      });
      final market = StoreMarketData.fromJson({
        'id': 9,
        'name': 'Fresh Market',
        'branch': 'Algiers',
        'status': 'active',
        'classification_id': 7,
        'image': '/media/markets/fresh-market.webp',
        'cover_image': '/media/markets/covers/fresh-market.webp',
        'description': 'Daily groceries',
        'delivery_time_min_minutes': 25,
        'delivery_time_max_minutes': 35,
        'product_count': 12,
        'minimum_product_price': '80.00',
        'is_liked': true,
        'is_popular': true,
        'market_type_ids': [11, 12, 11],
        'created_at': '2026-07-13T12:00:00Z',
        'subcategories': [
          {
            'id': 2,
            'name_ar': 'مشروبات',
            'name_en': 'Drinks',
            'description_ar': 'باردة وساخنة',
            'description_en': '',
            'sort_order': 2,
            'is_active': true,
          },
          {
            'id': 1,
            'name_ar': 'مخبوزات',
            'name_en': 'Bakery',
            'sort_order': 1,
            'is_active': true,
          },
          {
            'id': 3,
            'name_ar': 'مخفية',
            'name_en': 'Hidden',
            'sort_order': 0,
            'is_active': false,
          },
        ],
        'products': [_marketProduct()],
      });

      expect(classification.id, '7');
      expect(classification.name, 'Supermarket');
      expect(classification.marketCount, 2);
      expect(classification.marketCountLabel, '2 stores');
      expect(classification.classificationType, 'featured');
      expect(classification.marketTypes.single.id, '11');
      expect(classification.marketTypes.single.localizedName('ar'), 'برجر');
      expect(classification.marketTypes.single.localizedName('en'), 'Burger');
      expect(market.id, '9');
      expect(market.classificationId, '7');
      expect(market.isPopular, isTrue);
      expect(market.marketTypeIds, ['11', '12']);
      expect(market.image, endsWith('/media/markets/fresh-market.webp'));
      expect(
        market.coverImage,
        endsWith('/media/markets/covers/fresh-market.webp'),
      );
      expect(market.description, 'Daily groceries');
      expect(market.deliveryTimeLabel, '25-35 min');
      expect(market.effectiveProductCount, 12);
      expect(market.minimumProductPrice, 80);
      expect(market.isLiked, isTrue);
      expect(market.createdAt, DateTime.utc(2026, 7, 13, 12));
      expect(market.products.single.title, 'Red Apple');
      expect(market.products.single.brand, 'Fresh Market');
      expect(market.products.single.marketId, '9');
      expect(market.subcategories.map((item) => item.id), ['1', '2']);
      expect(market.subcategories.last.localizedName('en'), 'Drinks');
      expect(
        market.subcategories.last.localizedDescription('en'),
        'باردة وساخنة',
      );
    });

    test('gives featured categories priority in the eight display slots', () {
      final featuredOne = _classification('f1', 'featured');
      final featuredTwo = _classification('f2', 'featured');
      final normalOne = _classification('n1', 'normal');
      final normalTwo = _classification('n2', 'normal');
      final normalThree = _classification('n3', 'normal');
      final normalFour = _classification('n4', 'normal');
      final normalFive = _classification('n5', 'normal');
      final normalSix = _classification('n6', 'normal');
      final normalOverflow = _classification('n7', 'normal');
      final popular = _classification('p1', 'popular');
      final store = StoreData(
        commonClassifications: const [],
        classifications: [
          normalOne,
          popular,
          featuredOne,
          normalTwo,
          featuredTwo,
          normalThree,
          normalFour,
          normalFive,
          normalSix,
          normalOverflow,
        ],
        marketsByClassificationId: const {},
      );

      expect(store.featuredSlots.map((item) => item.id), [
        'f1',
        'f2',
        'n1',
        'n2',
        'n3',
        'n4',
        'n5',
        'n6',
      ]);
      expect(store.hasFeaturedOverflow, isTrue);
      expect(
        store.featuredCandidates.map((item) => item.id),
        isNot(contains('p1')),
      );
    });

    test('keeps all category stores and exposes popular stores separately', () {
      const regular = StoreMarketData(
        id: 'regular',
        name: 'Regular',
        branch: '',
        status: 'active',
        classificationId: '7',
        products: [],
        image: '',
        accentColorValue: 0xFF4F60F6,
      );
      const popular = StoreMarketData(
        id: 'popular',
        name: 'Popular',
        branch: '',
        status: 'active',
        classificationId: '7',
        products: [],
        image: '',
        accentColorValue: 0xFF4F60F6,
        isPopular: true,
      );
      final store = StoreData(
        commonClassifications: const [],
        classifications: const [],
        marketsByClassificationId: const {
          '7': [regular, popular],
        },
      );

      expect(store.marketsFor('7').map((market) => market.id), [
        'regular',
        'popular',
      ]);
      expect(store.popularMarketsFor('7').map((market) => market.id), [
        'popular',
      ]);
    });
  });
}

StoreClassificationData _classification(String id, String type) {
  return StoreClassificationData(
    id: id,
    name: id,
    marketCount: 1,
    products: const [],
    image: '',
    accentColorValue: 0xFF4F60F6,
    classificationType: type,
  );
}

Map<String, Object?> _marketProduct() {
  return {
    'id': 42,
    'name': 'Red Apple',
    'description': 'Fresh fruit',
    'image': '',
    'discount': '10.00',
    'category': {'id': 3, 'name': 'Fruit'},
  };
}
