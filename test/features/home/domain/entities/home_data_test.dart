import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/features/home/domain/entities/home_data.dart';

void main() {
  group('HomeData', () {
    test('maps backend home payload into offers, categories, and products', () {
      final home = HomeData.fromJson({
        'location': {
          'address_id': 12,
          'name': 'Home',
          'latitude': '36.7',
          'longitude': '3.0',
        },
        'offers': [
          {
            'id': 5,
            'title': 'Fresh offer',
            'description': 'Daily discount',
            'image': '',
            'type': 'discount',
            'discount': '15.00',
            'start_time': '2026-06-01T00:00:00Z',
            'end_time': '2026-06-30T00:00:00Z',
            'market': {'id': 2, 'name': 'Fresh Market'},
            'products': [_backendProduct()],
          },
        ],
        'market_classifications': [
          {
            'id': 3,
            'name': 'Supermarket',
            'markets': [
              {'id': 1, 'name': 'Fresh Market'},
              {'id': 2, 'name': 'Daily Market'},
            ],
          },
        ],
        'products': [_backendProduct()],
      });

      expect(home.location?.addressId, '12');
      expect(home.offers.single.title, 'Fresh offer');
      expect(home.offers.single.discountLabel, '15% off');
      expect(home.offers.single.products.single.price, '120.00');
      expect(home.categories.single.name, 'Supermarket');
      expect(home.categories.single.productCount, 2);
      expect(home.products.single.brand, 'Fresh Market');
      expect(home.products.single.image, AppAssets.temporaryMarketPlaceholder);
    });
  });
}

Map<String, Object?> _backendProduct() {
  return {
    'id': 42,
    'name': 'Red Apple',
    'description': 'Fresh fruit',
    'image': '',
    'discount': '10.00',
    'category': {'id': 3, 'name': 'Fruit'},
    'market': {'id': 9, 'name': 'Fresh Market'},
    'variants': [
      {'id': 1, 'price': '120.00', 'sku': 'SKU-1'},
    ],
  };
}
