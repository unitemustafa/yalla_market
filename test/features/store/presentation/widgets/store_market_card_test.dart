import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      'description uses two lines in a compact card at scale $scale',
      (tester) async {
        const description =
            'كل احتياجات البيت من منتجات طازجة وأطعمة ومشروبات يومية';
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Center(
                    child: SizedBox(
                      width: 230,
                      child: StoreMarketCard(
                        market: _market(1, description: description),
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final label = find.text(description);
        final paragraph = tester.renderObject<RenderParagraph>(label);
        final lines = paragraph
            .getBoxesForSelection(
              const TextSelection(
                baseOffset: 0,
                extentOffset: description.length,
              ),
            )
            .map((box) => box.top)
            .toSet();
        expect(lines, hasLength(2));
        final details = tester.getRect(
          find.byKey(const ValueKey('store_market_details')),
        );
        expect(tester.getRect(label).bottom, lessThan(details.bottom - 37));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('floats store details over the full-width cover', (tester) async {
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
      final coverFinder = find.byKey(const ValueKey('test_store_market_cover'));
      final cover = tester.getRect(coverFinder);
      expect(cover.width, 300);
      expect(cover.height, 126);
      expect(tester.widget<AppImage>(coverFinder).fit, BoxFit.cover);
      final logo = tester.getRect(
        find.byKey(const ValueKey('test_store_market_logo')),
      );
      final details = tester.getRect(
        find.byKey(const ValueKey('test_store_market_details')),
      );
      expect(cover.overlaps(details), isTrue);
      expect(details.left, greaterThan(cover.left));
      expect(details.right, lessThan(cover.right));
      expect(details.bottom, greaterThan(cover.bottom));
      expect(logo.top, greaterThan(details.top));
      expect(
        tester.getRect(find.text('Unified Store')).top,
        greaterThan(details.top),
      );
      expect(
        tester.getRect(find.text('Everyday essentials')).top,
        greaterThan(tester.getRect(find.text('Unified Store')).bottom),
      );
      expect(
        cover.overlaps(
          tester.getRect(
            find.byKey(const ValueKey('test_store_market_favorite')),
          ),
        ),
        isTrue,
      );
      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(
        tester.getSize(find.byType(StoreMarketCard)).height,
        StoreMarketCard.height,
      );
      expect(tester.takeException(), isNull);
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
    expect(image.source, AppAssets.defaultOffer);
  });

  testWidgets('fits compact iPhone widths with long Arabic content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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
    final logo = tester.getRect(
      find.byKey(const ValueKey('store_market_logo')),
    );
    expect(logo.left, greaterThan(tester.getRect(find.text(name.data!)).right));
    final products = tester.getRect(find.text('2 منتج'));
    final delivery = tester.getRect(find.text('20-30 دقيقة'));
    expect(products.center.dy, closeTo(delivery.center.dy, 1));
    expect(find.byIcon(Icons.verified), findsOneWidget);
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

StoreMarketData _market(
  int productCount, {
  String name = 'Unified Store',
  String description = 'Everyday essentials',
}) {
  return StoreMarketData(
    id: 'market',
    name: name,
    branch: '',
    status: 'active',
    classificationId: 'classification',
    products: List.generate(productCount, _product),
    image: AppAssets.defaultStore,
    coverImage: AppAssets.defaultOffer,
    description: description,
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
