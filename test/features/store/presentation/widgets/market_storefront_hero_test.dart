import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/presentation/widgets/market_storefront_hero.dart';

void main() {
  testWidgets('store hero keeps metadata and actions in RTL', (tester) async {
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
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 430.0, 768.0, 1024.0]) {
    testWidgets('restored banner and overlaid actions fit at ${width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: width >= 768 ? ThemeData.dark() : ThemeData.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              padding: const EdgeInsets.only(top: 24),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: MarketStorefrontHero(
                    market: _market,
                    onBack: () {},
                    onSearch: () {},
                    onShare: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final coverFinder = find.byKey(const ValueKey('storefront_cover'));
      final cover = tester.getRect(coverFinder);
      expect(cover.width, width);
      expect(cover.height, 238);
      expect(tester.widget<AppImage>(coverFinder).fit, BoxFit.cover);
      final details = tester.getRect(
        find.byKey(const ValueKey('storefront_details')),
      );
      expect(details.top, lessThan(cover.bottom));
      expect(details.bottom, lessThanOrEqualTo(342));
      for (final action in ['back', 'search', 'share', 'favorite']) {
        final button = tester.getRect(
          find.byKey(ValueKey('storefront_${action}_button')),
        );
        expect(button.bottom, lessThan(details.top));
        expect(button.top, greaterThanOrEqualTo(24));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('toolbar still invokes navigation, search and sharing', (
    tester,
  ) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarketStorefrontHero(
              market: _market,
              onBack: () => tapped.add('back'),
              onSearch: () => tapped.add('search'),
              onShare: () => tapped.add('share'),
            ),
          ),
        ),
      ),
    );
    for (final action in ['back', 'search', 'share']) {
      await tester.tap(find.byKey(ValueKey('storefront_${action}_button')));
    }
    expect(tapped, ['back', 'search', 'share']);
  });

  test('market data accepts normalized cover focal points', () {
    final market = StoreMarketData.fromJson({
      'id': 1,
      'name': 'Store',
      'image': AppAssets.defaultStore,
      'cover_image': AppAssets.emptyStoreLight,
      'cover_focus': {'x': 0.75, 'y': 0.2},
    });

    expect(market.coverFocus.x, 0.75);
    expect(market.coverFocus.y, 0.2);
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
