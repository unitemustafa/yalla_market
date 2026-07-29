import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/market_wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/wishlist_repository.dart';
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
    final marketCubit = MarketWishlistCubit(_MarketWishlistRepository());
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
    expect(tester.takeException(), isNull);
  });
}

class _WishlistRepository implements WishlistRepository {
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
    return ApiResult.success(List.unmodifiable(_items));
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
  @override
  Future<ApiResult<List<StoreMarketData>>> getItems() async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<bool>> setFavorite(String marketId, bool favorite) async {
    return ApiResult.success(favorite);
  }
}
