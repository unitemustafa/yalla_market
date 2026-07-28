import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/market_wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/market_wishlist_cubit.dart';

void main() {
  test('loads favorite stores and removes one successfully', () async {
    final repository = _MarketWishlistRepository([_market]);
    final cubit = MarketWishlistCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadForUser('user-1');
    expect(cubit.state.items.map((item) => item.id), ['market-1']);
    expect(cubit.isFavorite(_market), isTrue);

    await cubit.toggle(_market);

    expect(cubit.state.items, isEmpty);
    expect(cubit.isFavorite(_market), isFalse);
    expect(repository.lastFavorite, isFalse);
  });

  test('rolls back optimistic favorite when the request fails', () async {
    final repository = _MarketWishlistRepository(const [], failUpdates: true);
    final cubit = MarketWishlistCubit(repository);
    addTearDown(cubit.close);
    await cubit.loadForUser('user-1');

    await cubit.toggle(_market);

    expect(cubit.state.items, isEmpty);
    expect(cubit.isFavorite(_market), isFalse);
    expect(cubit.state.errorRevision, 1);
  });
}

const _market = StoreMarketData(
  id: 'market-1',
  name: 'Favorite Store',
  branch: '',
  status: 'active',
  classificationId: 'classification-1',
  products: [],
  image: '',
  accentColorValue: 0xFF013C7E,
);

class _MarketWishlistRepository implements MarketWishlistRepository {
  _MarketWishlistRepository(this.items, {this.failUpdates = false});

  final List<StoreMarketData> items;
  final bool failUpdates;
  bool? lastFavorite;

  @override
  Future<ApiResult<List<StoreMarketData>>> getItems() async {
    return ApiResult.success(items);
  }

  @override
  Future<ApiResult<bool>> setFavorite(String marketId, bool favorite) async {
    lastFavorite = favorite;
    if (failUpdates) {
      return const ApiResult.failure(UnknownFailure('Favorite update failed.'));
    }
    return ApiResult.success(favorite);
  }
}
