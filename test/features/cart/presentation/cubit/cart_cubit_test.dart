import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/domain/repositories/cart_repository.dart';
import 'package:yalla_market/features/cart/domain/usecases/cart_usecases.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';

import '../../../../helpers/domain_fixtures.dart';

void main() {
  group('CartCubit', () {
    test('loads the cart when it is created', () async {
      final cubit = CartCubit(
        _cartUseCases(_FakeCartRepository(items: const [sampleCartItem])),
      );
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([
          isEmpty,
          predicate<List<CartItemData>>(
            (items) => items.length == 1 && items.first.id == sampleCartItem.id,
          ),
        ]),
      );

      await cubit.loadCartForUser('user-a');
      await expectedStates;

      expect(cubit.state.single.id, sampleCartItem.id);
      await cubit.close();
    });

    test('adds items and clears stale error messages', () async {
      final repository = _FakeCartRepository();
      final cubit = CartCubit(_cartUseCases(repository));
      await cubit.loadCartForUser('user-a');

      expect(await cubit.addItem(sampleCartItem, 2), isTrue);

      expect(cubit.state.single.quantity, 2);
      expect(cubit.lastErrorMessage, isNull);
      await cubit.close();
    });

    test(
      'addItem reports failure without publishing a successful cart',
      () async {
        final repository = _FakeCartRepository();
        final cubit = CartCubit(_cartUseCases(repository));
        await cubit.loadCartForUser('user-a');
        repository.nextFailure = const ServerFailure('Could not save cart.');

        expect(await cubit.addItem(sampleCartItem, 2), isFalse);
        expect(cubit.state, isEmpty);
        expect(cubit.lastErrorMessage, 'Could not save cart.');
        await cubit.close();
      },
    );

    test('addItem without a session reports failure', () async {
      final cubit = CartCubit(_cartUseCases(_FakeCartRepository()));
      expect(await cubit.addItem(sampleCartItem, 1), isFalse);
      expect(cubit.state, isEmpty);
      await cubit.close();
      expect(await cubit.addItem(sampleCartItem, 1), isFalse);
    });

    for (final change in ['clear', 'switch', 'close']) {
      test('addItem reports no success after session $change', () async {
        final delay = Completer<void>();
        final cubit = CartCubit(
          _cartUseCases(_FakeCartRepository(addDelay: delay)),
        );
        await cubit.loadCartForUser('old-user');
        final adding = cubit.addItem(sampleCartItem, 1);
        switch (change) {
          case 'clear':
            cubit.clearSession();
          case 'switch':
            await cubit.loadCartForUser('new-user');
          case 'close':
            await cubit.close();
        }
        delay.complete();

        expect(await adding, isFalse);
        expect(cubit.state, isEmpty);
        if (!cubit.isClosed) await cubit.close();
      });
    }

    test(
      'keeps current cart state and records the last error on failure',
      () async {
        final repository = _FakeCartRepository(items: const [sampleCartItem]);
        final cubit = CartCubit(_cartUseCases(repository));
        await cubit.loadCartForUser('user-a');
        repository.nextFailure = const ServerFailure('Cart is unavailable.');

        await cubit.incrementQuantity(sampleCartItem.id);

        expect(cubit.state.single.quantity, sampleCartItem.quantity);
        expect(cubit.lastErrorMessage, 'Cart is unavailable.');
        await cubit.close();
      },
    );

    test('removes and clears items through the use cases', () async {
      final repository = _FakeCartRepository(items: const [sampleCartItem]);
      final cubit = CartCubit(_cartUseCases(repository));
      await cubit.loadCartForUser('user-a');

      await cubit.removeItem(sampleCartItem.id);
      expect(cubit.state, isEmpty);

      await cubit.addItem(sampleCartItem, 1);
      await cubit.clearLocalCart();

      expect(cubit.state, isEmpty);
      await cubit.close();
    });

    test(
      'clearSession clears visible state without removing storage',
      () async {
        SharedPreferences.setMockInitialValues({});
        final repository = CartRepositoryImpl();
        final cubit = CartCubit(_cartUseCases(repository));
        await cubit.loadCartForUser('user-a');
        await cubit.addItem(sampleCartItem, 1);

        cubit.clearSession();

        expect(cubit.state, isEmpty);
        final result = await repository.getItems('user-a');
        result.when(
          success: (items) => expect(items.single.id, sampleCartItem.id),
          failure: (failure) => fail(failure.message),
        );
        await cubit.close();
      },
    );

    test('addItem after loadCartForUser persists to storage', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = CartRepositoryImpl();
      final cubit = CartCubit(_cartUseCases(repository));

      await cubit.loadCartForUser('user-a');
      await cubit.addItem(sampleCartItem, 3);

      final reloaded = await repository.getItems('user-a');
      reloaded.when(
        success: (items) => expect(items.single.quantity, 3),
        failure: (failure) => fail(failure.message),
      );
      await cubit.close();
    });

    test('clearSession ignores a cart response from the old user', () async {
      final delay = Completer<void>();
      final repository = _FakeCartRepository(
        items: const [sampleCartItem],
        loadDelay: delay,
      );
      final cubit = CartCubit(_cartUseCases(repository));

      final load = cubit.loadCartForUser('old-user');
      cubit.clearSession();
      delay.complete();
      await load;

      expect(cubit.state, isEmpty);
      await cubit.close();
    });
  });
}

CartUseCases _cartUseCases(CartRepository repository) {
  return CartUseCases(
    getItems: GetCartItemsUseCase(repository),
    addItem: AddCartItemUseCase(repository),
    incrementQuantity: IncrementCartItemQuantityUseCase(repository),
    decrementQuantity: DecrementCartItemQuantityUseCase(repository),
    removeItem: RemoveCartItemUseCase(repository),
    clearCart: ClearCartUseCase(repository),
  );
}

class _FakeCartRepository implements CartRepository {
  _FakeCartRepository({
    List<CartItemData> items = const [],
    this.loadDelay,
    this.addDelay,
  }) : _items = List.of(items);

  final List<CartItemData> _items;
  final Completer<void>? loadDelay;
  final Completer<void>? addDelay;
  Failure? nextFailure;

  Future<ApiResult<List<CartItemData>>> _result() async {
    if (nextFailure case final failure?) {
      nextFailure = null;
      return ApiResult.failure(failure);
    }

    return ApiResult.success(List.unmodifiable(_items));
  }

  @override
  Future<ApiResult<List<CartItemData>>> getItems(String userKey) async {
    await loadDelay?.future;
    return _result();
  }

  @override
  Future<ApiResult<List<CartItemData>>> addItem(
    String userKey,
    CartItemData item,
    int quantityToAdd,
  ) async {
    await addDelay?.future;
    final existingIndex = _items.indexWhere(
      (cartItem) => cartItem.id == item.id,
    );
    if (existingIndex == -1) {
      _items.add(item.copyWith(quantity: quantityToAdd));
    } else {
      final existing = _items[existingIndex];
      _items[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantityToAdd,
      );
    }

    return _result();
  }

  @override
  Future<ApiResult<List<CartItemData>>> incrementQuantity(
    String userKey,
    String id,
  ) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      _items[index] = item.copyWith(quantity: item.quantity + 1);
    }

    return _result();
  }

  @override
  Future<ApiResult<List<CartItemData>>> decrementQuantity(
    String userKey,
    String id,
  ) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      _items[index] = item.copyWith(quantity: item.quantity - 1);
    }

    return _result();
  }

  @override
  Future<ApiResult<List<CartItemData>>> removeItem(
    String userKey,
    String id,
  ) async {
    _items.removeWhere((item) => item.id == id);
    return _result();
  }

  @override
  Future<ApiResult<List<CartItemData>>> clear(String userKey) async {
    _items.clear();
    return _result();
  }
}
