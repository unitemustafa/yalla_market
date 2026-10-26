import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/domain/favorite_page.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/wishlist/data/repositories/wishlist_remote_repository_impl.dart';
import 'package:yalla_market/features/wishlist/data/repositories/market_wishlist_remote_repository.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';
import '../../helpers/fake_api_client.dart';

void main() {
  test(
    'remote pages retain full membership and unlike an unloaded product without fetching all cards',
    () async {
      final api = FakeApiClient((request) {
        if (request.path.endsWith('/99/unlike/')) {
          expect(request.method, 'DELETE');
          return {'liked': false};
        }
        expect(request.queryParameters, {
          'page': 1,
          'page_size': 30,
          'include_ids': 'true',
        });
        return {
          'count': 100,
          'next': 'http://fixture/likes/?page=2',
          'liked_ids': List.generate(100, (i) => i + 1),
          'results': [
            {
              'id': 1,
              'name': 'First',
              'variants': [
                {'id': 1, 'price': '10'},
              ],
            },
          ],
        };
      });
      final repository = WishlistRemoteRepositoryImpl(api);
      final page =
          (await repository.getPage('user')
                  as ApiSuccess<FavoritePage<WishlistItem>>)
              .data;
      expect(page.items.length, 1);
      expect(page.favoriteIds!.contains('99'), isTrue);
      await repository.toggleItem(
        'user',
        const WishlistItem(
          productId: '99',
          title: 'Unloaded',
          image: '',
          brand: '',
          price: '10',
        ),
      );
      expect(api.requests.length, 2);
      expect(api.requests.last.path, '/catalog/products/99/unlike/');
    },
  );
  test(
    'missing complete membership is a typed failure instead of showing incorrect hearts',
    () async {
      final api = FakeApiClient(
        (_) => {'count': 0, 'next': null, 'results': []},
      );
      final result = await WishlistRemoteRepositoryImpl(api).getPage('user');
      expect(result, isA<ApiFailure<FavoritePage<WishlistItem>>>());
    },
  );
  test('later store pages do not request the full ID set again', () async {
    final api = FakeApiClient((request) {
      expect(request.queryParameters, {'page': 2, 'page_size': 30});
      return {
        'count': 31,
        'next': null,
        'results': [
          {'id': 31, 'name': 'Last', 'classification_id': 1},
        ],
      };
    });
    final result = await MarketWishlistRemoteRepository(api).getPage(page: 2);
    result.when(
      success: (page) {
        expect(page.items.single.id, '31');
        expect(page.favoriteIds, isNull);
        expect(page.hasMore, isFalse);
      },
      failure: (failure) => fail(failure.message),
    );
  });
}
