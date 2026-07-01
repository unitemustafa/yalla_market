import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';

void main() {
  group('WishlistRepositoryImpl', () {
    const userKey = 'user_1';
    late WishlistRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = WishlistRepositoryImpl();
    });

    test('adds item when it is not in wishlist', () async {
      const item = WishlistItem(
        productId: 'product_1',
        image: 'image.png',
        title: 'Fresh product',
        brand: 'Yalla',
        price: r'$10',
      );

      final result = await repository.toggleItem(userKey, item);

      result.when(
        success: (items) => expect(items, hasLength(1)),
        failure: (failure) => fail(failure.message),
      );
    });

    test('removes item when it already exists', () async {
      const item = WishlistItem(
        productId: 'product_1',
        image: 'image.png',
        title: 'Fresh product',
        brand: 'Yalla',
        price: r'$10',
      );

      await repository.toggleItem(userKey, item);
      final result = await repository.toggleItem(userKey, item);

      result.when(
        success: (items) => expect(items, isEmpty),
        failure: (failure) => fail(failure.message),
      );
    });
  });
}
