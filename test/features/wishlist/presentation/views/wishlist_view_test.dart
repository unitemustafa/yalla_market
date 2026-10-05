import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/presentation/widgets/store_market_card.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/market_wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/domain/usecases/market_wishlist_usecases.dart';
import 'package:yalla_market/features/wishlist/domain/usecases/wishlist_usecases.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/market_wishlist_cubit.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:yalla_market/features/wishlist/presentation/views/wishlist_view.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  testWidgets('favorite products always use two columns', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final wishlistRepository = _WishlistRepository();
    final wishlistCubit = WishlistCubit(
      WishlistUseCases(
        getItems: GetWishlistItemsUseCase(wishlistRepository),
        toggleItem: ToggleWishlistItemUseCase(wishlistRepository),
      ),
    );
    final marketCubit = MarketWishlistCubit(
      MarketWishlistUseCases(_MarketWishlistRepository()),
    );
    final cartCubit = makeCartCubit();
    addTearDown(wishlistCubit.close);
    addTearDown(marketCubit.close);
    addTearDown(cartCubit.close);
    await wishlistCubit.loadWishlistForUser('user');
    await marketCubit.loadForUser('user');

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: wishlistCubit),
          BlocProvider.value(value: marketCubit),
          BlocProvider.value(value: cartCubit),
        ],
        child: const MaterialApp(home: WishlistView()),
      ),
    );
    await tester.pump();

    final grid = tester.widget<GridView>(
      find.descendant(
        of: find.byKey(const ValueKey('wishlist_products_grid')),
        matching: find.byType(GridView),
      ),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(
      delegate.mainAxisExtent,
      ProductCardVertical.storefrontGridMainAxisExtent,
    );
    expect(
      tester
          .widgetList<ProductCardVertical>(find.byType(ProductCardVertical))
          .every((card) => !card.compact),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  for (final direction in TextDirection.values) {
    testWidgets('favorite stores scroll horizontally and open in $direction', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _WishlistRepository(empty: true);
      final wishlist = WishlistCubit(
        WishlistUseCases(
          getItems: GetWishlistItemsUseCase(repository),
          toggleItem: ToggleWishlistItemUseCase(repository),
        ),
      );
      final markets = List.generate(
        3,
        (index) => StoreMarketData(
          id: 'market-$index',
          name: 'Store $index',
          branch: '',
          status: 'active',
          classificationId: 'category',
          products: const [],
          image: AppAssets.defaultStore,
          coverImage: AppAssets.emptyStoreLight,
          deliveryTimeMinMinutes: 10,
          deliveryTimeMaxMinutes: 30,
          accentColorValue: 0xFF013C7E,
        ),
      );
      final marketWishlist = MarketWishlistCubit(
        MarketWishlistUseCases(_MarketWishlistRepository(markets)),
      );
      final cart = makeCartCubit();
      addTearDown(wishlist.close);
      addTearDown(marketWishlist.close);
      addTearDown(cart.close);
      await wishlist.loadWishlistForUser('user');
      await marketWishlist.loadForUser('user');
      BrandProductsRouteArgs? openedStore;
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: wishlist),
            BlocProvider.value(value: marketWishlist),
            BlocProvider.value(value: cart),
          ],
          child: MaterialApp(
            onGenerateRoute: (settings) {
              expect(settings.name, AppRoutes.brandProducts);
              openedStore = settings.arguments! as BrandProductsRouteArgs;
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Opened store')),
              );
            },
            home: Directionality(
              textDirection: direction,
              child: const WishlistView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byKey(
        const ValueKey('wishlist_stores_horizontal_slider'),
      );
      expect(tester.widget<ListView>(slider).scrollDirection, Axis.horizontal);
      final first = tester.getRect(
        find.byKey(const ValueKey('wishlist_store_market-0')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('wishlist_store_market-1')),
      );
      expect(first.height, StoreMarketCard.height);
      expect(first.center.dy, second.center.dy);
      expect(first.width, lessThan(tester.getSize(slider).width));

      await tester.drag(
        slider,
        Offset(direction == TextDirection.rtl ? 500 : -500, 0),
      );
      await tester.pumpAndSettle();
      final last = find.byKey(const ValueKey('wishlist_store_market-2'));
      expect(last.hitTestable(), findsOneWidget);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(openedStore?.marketId, 'market-2');
      expect(tester.takeException(), isNull);
    });
  }
}

class _WishlistRepository implements WishlistRepository {
  _WishlistRepository({this.empty = false});

  final bool empty;
  final _items = List.generate(
    3,
    (index) => WishlistItem(
      productId: 'product-$index',
      image: AppAssets.defaultProduct,
      title: 'Product $index',
      brand: 'Store',
      price: '100',
    ),
  );

  @override
  Future<ApiResult<List<WishlistItem>>> getItems(String userKey) async {
    return ApiResult.success(empty ? const [] : List.unmodifiable(_items));
  }

  @override
  Future<ApiResult<List<WishlistItem>>> toggleItem(
    String userKey,
    WishlistItem item,
  ) async {
    return ApiResult.success(List.unmodifiable(_items));
  }
}

class _MarketWishlistRepository implements MarketWishlistRepository {
  _MarketWishlistRepository([this.items = const []]);

  final List<StoreMarketData> items;
  @override
  Future<ApiResult<List<StoreMarketData>>> getItems() async {
    return ApiResult.success(items);
  }

  @override
  Future<ApiResult<bool>> setFavorite(String marketId, bool favorite) async {
    return ApiResult.success(favorite);
  }
}
