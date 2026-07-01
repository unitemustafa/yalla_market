import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';

void main() {
  group('CartRepositoryImpl', () {
    late CartRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = CartRepositoryImpl();
    });

    test('adds a new item to the cart', () async {
      const item = CartItemData(
        id: 'new-item',
        image: 'image.png',
        brand: 'Yalla',
        title: 'New product',
        price: 10,
        quantity: 1,
      );

      final result = await repository.addItem('user-a', item, 2);

      result.when(
        success: (items) {
          final addedItem = items.firstWhere((item) => item.id == 'new-item');
          expect(addedItem.quantity, 2);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('increments existing item quantity when adding same item', () async {
      const item = CartItemData(
        id: 'same-item',
        image: 'image.png',
        brand: 'Yalla',
        title: 'Same product',
        price: 10,
        quantity: 1,
      );

      await repository.addItem('user-a', item, 1);
      final result = await repository.addItem('user-a', item, 3);

      result.when(
        success: (items) {
          final addedItem = items.firstWhere((item) => item.id == 'same-item');
          expect(addedItem.quantity, 4);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('does not decrement quantity below one', () async {
      const firstItem = CartItemData(
        id: 'single-item',
        image: 'image.png',
        brand: 'Yalla',
        title: 'Single product',
        price: 10,
        quantity: 1,
      );
      await repository.addItem('user-a', firstItem, 1);

      final result = await repository.decrementQuantity('user-a', firstItem.id);

      result.when(
        success: (items) {
          final updatedItem = items.firstWhere(
            (item) => item.id == firstItem.id,
          );
          expect(
            updatedItem.quantity,
            firstItem.quantity == 1 ? 1 : firstItem.quantity - 1,
          );
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('starts with an empty cart', () async {
      final result = await repository.getItems('user-a');

      result.when(
        success: (items) => expect(items, isEmpty),
        failure: (failure) => fail(failure.message),
      );
    });

    test('persists cart items in SharedPreferences', () async {
      const item = CartItemData(
        id: 'persisted-item',
        productId: 'product-1',
        image: 'image.png',
        brand: 'Yalla',
        title: 'Persisted product',
        price: 15,
        quantity: 1,
      );

      await repository.addItem('user-a', item, 2);
      final reloadedRepository = CartRepositoryImpl();
      final result = await reloadedRepository.getItems('user-a');

      result.when(
        success: (items) {
          expect(items.single.id, 'persisted-item');
          expect(items.single.quantity, 2);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('keeps carts scoped per user', () async {
      const itemA = CartItemData(
        id: 'item-a',
        image: 'a.png',
        brand: 'Yalla',
        title: 'A product',
        price: 10,
        quantity: 1,
      );
      const itemB = CartItemData(
        id: 'item-b',
        image: 'b.png',
        brand: 'Yalla',
        title: 'B product',
        price: 20,
        quantity: 1,
      );

      await repository.addItem('user-a', itemA, 1);
      await repository.addItem('user-b', itemB, 1);

      final resultA = await repository.getItems('user-a');
      final resultB = await repository.getItems('user-b');

      resultA.when(
        success: (items) => expect(items.single.id, 'item-a'),
        failure: (failure) => fail(failure.message),
      );
      resultB.when(
        success: (items) => expect(items.single.id, 'item-b'),
        failure: (failure) => fail(failure.message),
      );
    });

    test('returns empty cart and removes corrupted json', () async {
      SharedPreferences.setMockInitialValues({'cart_user_user-a': '{bad json'});
      repository = CartRepositoryImpl();

      final result = await repository.getItems('user-a');

      result.when(
        success: (items) => expect(items, isEmpty),
        failure: (failure) => fail(failure.message),
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey('cart_user_user-a'), isFalse);
    });
  });
}
