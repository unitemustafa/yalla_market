import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/home/domain/entities/home_data.dart';

void main() {
  test(
    'parses multi-market package metadata and preserves product markets',
    () {
      final offer = HomeOfferData.fromJson({
        'id': 10,
        'title': 'باكج المدينة',
        'description': '',
        'image': '',
        'type': 'package',
        'discount': '15.00',
        'is_multi_market': true,
        'market_count': 2,
        'market_names_summary': 'الأول، الثاني',
        'markets': [
          {'id': 1, 'name': 'الأول', 'branch': ''},
          {'id': 2, 'name': 'الثاني', 'branch': ''},
        ],
        'products': [
          {'id': 101, 'name': 'أ', 'market_id': 1, 'price': '10.00'},
          {'id': 202, 'name': 'ب', 'market_id': 2, 'price': '20.00'},
        ],
      });

      expect(offer.isMultiMarket, isTrue);
      expect(offer.marketCount, 2);
      expect(offer.markets.map((market) => market.id), ['1', '2']);
      expect(offer.marketNamesSummary, 'الأول، الثاني');
      expect(offer.products.map((product) => product.marketId), ['1', '2']);
    },
  );
}
