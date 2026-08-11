import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/presentation/widgets/store_market_card.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/market_wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/domain/usecases/market_wishlist_usecases.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/market_wishlist_cubit.dart';

void main() {
  testWidgets('renders one cover, overlaid logo, and store metadata', (
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
        find.byKey(const ValueKey('test_store_market_cover')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('test_store_market_logo')),
        findsOneWidget,
      );
      expect(find.text('20-30 min'), findsOneWidget);
      expect(
        tester.getSize(find.byType(StoreMarketCard)).height,
        StoreMarketCard.height,
      );
    }
  });

  testWidgets('uses the configured cover in dark mode', (tester) async {
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

    final image = tester.widget<AppImage>(
      find.byKey(const ValueKey('dark_store_market_cover')),
    );
    expect(image.source, AppAssets.emptyStoreLight);
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
    final name = tester.widget<Text>(
      find.text('اسم محل طويل جدًا لاختبار العرض على الآيفون الصغير'),
    );
    expect(name.textAlign, TextAlign.start);
  });

  testWidgets('favorite button toggles without opening the store card', (
    tester,
  ) async {
    final repository = _FavoriteRepository();
    final cubit = MarketWishlistCubit(MarketWishlistUseCases(repository));
    addTearDown(cubit.close);
    await cubit.loadForUser('user');
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: StoreMarketCard(
                market: _market(1),
                keyPrefix: 'interactive',
                onTap: () => opened = true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('interactive_market_favorite')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(cubit.isFavorite(_market(1)), isTrue);
    expect(repository.lastFavorite, isTrue);
    expect(opened, isFalse);
    expect(find.text('Store added to favorites'), findsOneWidget);
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
    coverImage: AppAssets.emptyStoreLight,
    deliveryTimeMinMinutes: 20,
    deliveryTimeMaxMinutes: 30,
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

class _FavoriteRepository implements MarketWishlistRepository {
  bool? lastFavorite;

  @override
  Future<ApiResult<List<StoreMarketData>>> getItems() async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<bool>> setFavorite(String marketId, bool favorite) async {
    lastFavorite = favorite;
    return ApiResult.success(favorite);
  }
}
