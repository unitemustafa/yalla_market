import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/presentation/widgets/store_market_card.dart';

void main() {
  testWidgets('always renders three image slots and fills missing products', (
    tester,
  ) async {
    for (var productCount = 0; productCount <= 3; productCount++) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: StoreMarketCard(
                  market: _market(productCount),
                  keyPrefix: 'test_store',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('test_store_market_product_0')),
        productCount > 0 ? findsOneWidget : findsNothing,
      );
      for (var index = 0; index < 3; index++) {
        final kind = index < productCount ? 'product' : 'default';
        expect(
          find.byKey(ValueKey('test_store_market_${kind}_$index')),
          findsOneWidget,
        );
      }
      expect(
        tester.getSize(find.byType(StoreMarketCard)).height,
        StoreMarketCard.height,
      );
      if (productCount == 0) {
        final firstDefault = tester.widget<AppImage>(
          find.byKey(const ValueKey('test_store_market_default_0')),
        );
        expect(firstDefault.source, AppAssets.emptyStoreLight);
      }
    }
  });

  testWidgets('uses the dark placeholder for every missing slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: StoreMarketCard(
              market: _market(1),
              keyPrefix: 'dark_store',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    for (final index in [1, 2]) {
      final image = tester.widget<AppImage>(
        find.byKey(ValueKey('dark_store_market_default_$index')),
      );
      expect(image.source, AppAssets.emptyStoreDark);
    }
  });

  testWidgets('fits compact iPhone widths with long Arabic content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StoreMarketCard(
                market: _market(
                  2,
                  name: 'اسم محل طويل جدًا لاختبار العرض على الآيفون الصغير',
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(StoreMarketCard)).width, 288);
    expect(
      tester.getSize(find.byType(StoreMarketCard)).height,
      StoreMarketCard.height,
    );
  });
}

StoreMarketData _market(int productCount, {String name = 'Unified Store'}) {
  return StoreMarketData(
    id: 'market',
    name: name,
    branch: '',
    status: 'active',
    classificationId: 'classification',
    products: List.generate(productCount, _product),
    image: AppAssets.defaultStore,
    accentColorValue: 0xFF013C7E,
  );
}

ProductData _product(int index) {
  return ProductData(
    id: 'product-$index',
    image: AppAssets.defaultProduct,
    title: 'Product $index',
    brand: 'Unified Store',
    price: '100',
    oldPrice: null,
    discount: '',
    tags: const [],
  );
}
