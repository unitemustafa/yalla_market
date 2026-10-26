import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/domain/favorite_page.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/market_wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/domain/usecases/wishlist_usecases.dart';
import 'package:yalla_market/features/wishlist/domain/usecases/market_wishlist_usecases.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/market_wishlist_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'stress_fixtures.dart';

WishlistCubit _productsCubit(_Products repository) => WishlistCubit(
  WishlistUseCases(
    getItems: GetWishlistItemsUseCase(repository),
    toggleItem: ToggleWishlistItemUseCase(repository),
  ),
);

void main() {
  test(
    'unloaded favorite IDs stay liked and removing a row cannot skip a page boundary',
    () async {
      final repository = _Products();
      final cubit = _productsCubit(repository);
      addTearDown(cubit.close);
      await cubit.loadWishlistForUser('customer');
      expect(cubit.state.length, 30);
      expect(cubit.isFavorite('100'), isTrue);
      await cubit.toggleItem(cubit.state.first);
      expect(cubit.isFavorite('1'), isFalse);
      await Future.wait([cubit.loadMore(), cubit.loadMore()]);
      expect(repository.pages, [1, 1, 2]);
      expect(
        cubit.state.map((i) => i.productId),
        List.generate(60, (i) => '${i + 2}'),
      );
      expect(cubit.isFavorite('100'), isTrue);
    },
  );
  test(
    'failed favorite page retries the same cursor and late pages cannot restore a logged out session',
    () async {
      final repository = _Products();
      final cubit = _productsCubit(repository);
      addTearDown(cubit.close);
      await cubit.loadWishlistForUser('customer');
      repository.fail = true;
      await cubit.loadMore();
      expect((cubit.state as WishlistState).moreError, 'offline');
      expect(cubit.state.length, 30);
      repository.fail = false;
      await cubit.loadMore();
      expect(cubit.state.length, 60);
      expect(repository.pages, [1, 2, 2]);
      final pending = Completer<ApiResult<FavoritePage<WishlistItem>>>();
      repository.pending = pending;
      final more = cubit.loadMore();
      await Future<void>.delayed(Duration.zero);
      cubit.clearSession();
      pending.complete(
        ApiResult.success(
          FavoritePage(
            items: repository.all.skip(60).take(30).toList(),
            count: 100,
            hasMore: true,
          ),
        ),
      );
      await more;
      expect(cubit.state, isEmpty);
      expect(cubit.isFavorite('100'), isFalse);
    },
  );
  test(
    'store favorites keep complete membership and rollback failed optimistic changes',
    () async {
      final repository = _Markets();
      final cubit = MarketWishlistCubit(MarketWishlistUseCases(repository));
      addTearDown(cubit.close);
      await cubit.loadForUser('customer');
      expect(cubit.state.items.length, 30);
      expect(cubit.isFavorite(repository.all.last), isTrue);
      repository.fail = true;
      expect(await cubit.toggle(repository.all.last), isNull);
      expect(cubit.isFavorite(repository.all.last), isTrue);
      repository.fail = false;
      await cubit.toggle(repository.all.first);
      await Future.wait([cubit.loadMore(), cubit.loadMore()]);
      expect(
        cubit.state.items.map((i) => i.id),
        List.generate(60, (i) => '${i + 2}'),
      );
      expect(cubit.isFavorite(repository.all.last), isTrue);
      expect(repository.pages, [1, 1, 2]);
    },
  );
}

class _Products implements WishlistRepository, PagedWishlistRepository {
  final all = StressFixtures(productCount: 100, listCount: 100).wishlist;
  late final List<WishlistItem> remaining = List.of(all);
  final loaded = <WishlistItem>[];
  final pages = <int>[];
  bool fail = false;
  Completer<ApiResult<FavoritePage<WishlistItem>>>? pending;
  @override
  Future<ApiResult<List<WishlistItem>>> getItems(String key) =>
      throw StateError('Full download is not allowed');
  @override
  Future<ApiResult<FavoritePage<WishlistItem>>> getPage(
    String key, {
    int page = 1,
  }) async {
    pages.add(page);
    if (pending != null) return pending!.future;
    if (fail) return const ApiResult.failure(ServerFailure('offline'));
    final rows = remaining.skip((page - 1) * 30).take(30).toList();
    if (page == 1) loaded.clear();
    loaded.addAll(rows);
    return ApiResult.success(
      FavoritePage(
        items: rows,
        count: remaining.length,
        hasMore: page * 30 < remaining.length,
        favoriteIds: page == 1
            ? remaining.map((i) => i.productId).toSet()
            : null,
      ),
    );
  }

  @override
  Future<ApiResult<List<WishlistItem>>> toggleItem(
    String key,
    WishlistItem item,
  ) async {
    remaining.removeWhere((i) => i.productId == item.productId);
    loaded.removeWhere((i) => i.productId == item.productId);
    return ApiResult.success(List.of(loaded));
  }
}

class _Markets
    implements MarketWishlistRepository, PagedMarketWishlistRepository {
  final all = StressFixtures(productCount: 1, listCount: 100).markets;
  late final remaining = List<StoreMarketData>.of(all);
  final pages = <int>[];
  bool fail = false;
  @override
  Future<ApiResult<List<StoreMarketData>>> getItems() =>
      throw StateError('Full download is not allowed');
  @override
  Future<ApiResult<FavoritePage<StoreMarketData>>> getPage({
    int page = 1,
  }) async {
    pages.add(page);
    return ApiResult.success(
      FavoritePage(
        items: remaining.skip((page - 1) * 30).take(30).toList(),
        count: remaining.length,
        hasMore: page * 30 < remaining.length,
        favoriteIds: page == 1 ? remaining.map((i) => i.id).toSet() : null,
      ),
    );
  }

  @override
  Future<ApiResult<bool>> setFavorite(String id, bool favorite) async {
    if (fail) return const ApiResult.failure(ServerFailure('offline'));
    remaining.removeWhere((i) => i.id == id);
    return const ApiResult.success(false);
  }
}
