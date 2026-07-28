import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/presentation/widgets/market_storefront_hero.dart';

void main() {
  testWidgets('store hero keeps compact Talabat-like proportions in RTL', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: MarketStorefrontHero(
              market: _market,
              onBack: () {},
              onSearch: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('storefront_cover')), findsOneWidget);
    expect(find.byKey(const ValueKey('storefront_logo')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('storefront_search_button')),
      findsOneWidget,
    );
    expect(find.text('20-35 min'), findsOneWidget);
    expect(find.textContaining('3 products'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('store_product_search_field')),
      findsNothing,
    );
    expect(
      tester.getSize(find.byType(MarketStorefrontHero)).height,
      lessThan(360),
    );
    expect(tester.takeException(), isNull);
  });
}

const _market = StoreMarketData(
  id: 'market',
  name: 'A compact store name',
  branch: '',
  status: 'active',
  classificationId: 'food',
  products: [],
  productCount: 3,
  image: AppAssets.defaultStore,
  coverImage: AppAssets.emptyStoreLight,
  description: 'Fresh products delivered to your door',
  deliveryTimeMinMinutes: 20,
  deliveryTimeMaxMinutes: 35,
  minimumProductPrice: 45,
  accentColorValue: 0xFF013C7E,
);
