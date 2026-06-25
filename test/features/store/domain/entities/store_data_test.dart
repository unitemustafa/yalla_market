import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';

void main() {
  group('Store data mapping', () {
    test('maps classification and market payloads from backend', () {
      final classification = StoreClassificationData.fromJson({
        'id': 7,
        'name': 'Supermarket',
        'product_count': 4,
        'products': [_marketProduct()],
      });
      final market = StoreMarketData.fromJson({
        'id': 9,
        'name': 'Fresh Market',
        'branch': 'Algiers',
        'status': 'active',
        'classification_id': 7,
        'products': [_marketProduct()],
      });

      expect(classification.id, '7');
      expect(classification.name, 'Supermarket');
      expect(classification.productCount, 4);
      expect(market.id, '9');
      expect(market.classificationId, '7');
      expect(market.products.single.title, 'Red Apple');
      expect(market.products.single.brand, 'Fresh Market');
      expect(market.products.single.marketId, '9');
    });
  });
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
