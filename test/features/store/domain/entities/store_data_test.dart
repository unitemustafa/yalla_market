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
        'products': [_marketProduct()],
      });
      final market = StoreMarketData.fromJson({
        'id': 9,
        'name': 'Fresh Market',
        'branch': 'Algiers',
        'status': 'active',
        'classification_id': 7,
        'is_popular': true,
        'created_at': '2026-07-13T12:00:00Z',
        'products': [_marketProduct()],
      });

      expect(classification.id, '7');
      expect(classification.name, 'Supermarket');
      expect(classification.marketCount, 2);
      expect(classification.marketCountLabel, '2 stores');
      expect(classification.classificationType, 'featured');
      expect(market.id, '9');
      expect(market.classificationId, '7');
      expect(market.isPopular, isTrue);
      expect(market.createdAt, DateTime.utc(2026, 7, 13, 12));
      expect(market.products.single.title, 'Red Apple');
      expect(market.products.single.brand, 'Fresh Market');
      expect(market.products.single.marketId, '9');
    });

    test('gives featured categories priority in the four display slots', () {
      final featuredOne = _classification('f1', 'featured');
      final featuredTwo = _classification('f2', 'featured');
      final normalOne = _classification('n1', 'normal');
      final normalTwo = _classification('n2', 'normal');
      final normalOverflow = _classification('n3', 'normal');
      final popular = _classification('p1', 'popular');
      final store = StoreData(
        commonClassifications: const [],
        classifications: [
          normalOne,
          popular,
          featuredOne,
          normalTwo,
          featuredTwo,
          normalOverflow,
        ],
        marketsByClassificationId: const {},
      );

      expect(store.featuredSlots.map((item) => item.id), [
        'f1',
        'f2',
        'n1',
        'n2',
      ]);
      expect(store.hasFeaturedOverflow, isTrue);
      expect(
        store.featuredCandidates.map((item) => item.id),
        isNot(contains('p1')),
      );
    });

    test('places popular stores first inside their classification', () {
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
        'popular',
        'regular',
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
