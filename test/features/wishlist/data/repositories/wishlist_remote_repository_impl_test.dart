import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/wishlist/data/repositories/wishlist_remote_repository_impl.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('WishlistRemoteRepositoryImpl', () {
    test('GET likes parses product list into wishlist items', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/catalog/products/likes/');
        return [
          {
            'id': 2,
            'market': {
              'id': 5,
              'name': 'Yalla Fresh Market',
              'classification_id': 2,
            },
            'category': {'id': 2, 'name': 'Produce'},
            'name': 'Red Apple',
            'image': null,
            'discount': '0.00',
            'variants': [
              {'id': 2, 'price': '320.00', 'sku': 'SEED-01-1'},
            ],
          },
        ];
      });
      final repository = WishlistRemoteRepositoryImpl(apiClient);

      final result = await repository.getItems('user_1');

      result.when(
        success: (items) {
          expect(items, hasLength(1));
          expect(items.single.productId, '2');
          expect(items.single.title, 'Red Apple');
          expect(items.single.brand, 'Yalla Fresh Market');
          expect(items.single.price, '320.00');
          expect(items.single.discount, '0.00');
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('like product calls product like endpoint', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'POST');
        expect(request.path, '/catalog/products/2/like/');
        return {'product_id': 2, 'liked': true};
      });
      final repository = WishlistRemoteRepositoryImpl(apiClient);

      final result = await repository.toggleItem(
        'user_1',
        testWishlistItem(productId: '2'),
      );

      result.when(
        success: (items) {
          expect(items, hasLength(1));
          expect(items.single.productId, '2');
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('unlike product calls product unlike endpoint', () async {
      final apiClient = FakeApiClient((request) {
        if (request.method == 'GET') {
          expect(request.path, '/catalog/products/likes/');
          return [
            {
              'id': 2,
              'market': {'name': 'Yalla Fresh Market'},
              'name': 'Red Apple',
              'image': null,
              'variants': [
                {'id': 2, 'price': '320.00'},
              ],
            },
          ];
        }

        expect(request.method, 'DELETE');
        expect(request.path, '/catalog/products/2/unlike/');
        return {'product_id': 2, 'liked': false};
      });
      final repository = WishlistRemoteRepositoryImpl(apiClient);

      await repository.getItems('user_1');
      final result = await repository.toggleItem(
        'user_1',
        testWishlistItem(productId: '2'),
      );

      result.when(
        success: (items) => expect(items, isEmpty),
        failure: (failure) => fail(failure.message),
      );
    });
  });
}

WishlistItem testWishlistItem({required String productId}) {
  return WishlistItem(
    productId: productId,
    image: 'apple.png',
    title: 'Red Apple',
    brand: 'Yalla Fresh Market',
    price: '320.00',
  );
}
