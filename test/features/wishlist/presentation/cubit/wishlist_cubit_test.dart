import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/domain/usecases/wishlist_usecases.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import '../../../../helpers/domain_fixtures.dart';

void main() {
  group('WishlistCubit', () {
    test('loads wishlist items for the current user', () async {
      final cubit = WishlistCubit(
        _wishlistUseCases(
          _FakeWishlistRepository(items: const [sampleWishlistItem]),
        ),
      );
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([
          isEmpty,
          predicate<List<WishlistItem>>(
            (items) =>
                items.length == 1 &&
                items.first.title == sampleWishlistItem.title,
          ),
        ]),
      );

      await cubit.loadWishlistForUser(sampleUser.id);
      await expectedStates;

      expect(cubit.isFavorite(sampleWishlistItem.productId), isTrue);
      await cubit.close();
    });

    test('toggles an item in and out of the wishlist', () async {
      final repository = _FakeWishlistRepository();
      final cubit = WishlistCubit(_wishlistUseCases(repository));
      await cubit.loadWishlistForUser(sampleUser.id);

      await cubit.toggleItem(sampleWishlistItem);
      expect(cubit.isFavorite(sampleWishlistItem.productId), isTrue);

      await cubit.toggleItem(sampleWishlistItem);
      expect(cubit.isFavorite(sampleWishlistItem.productId), isFalse);
      await cubit.close();
    });

    test('keeps current state when toggling fails', () async {
      final repository = _FakeWishlistRepository(
        items: const [sampleWishlistItem],
      );
      final cubit = WishlistCubit(_wishlistUseCases(repository));
      await cubit.loadWishlistForUser(sampleUser.id);
      repository.nextFailure = const ServerFailure('Wishlist is unavailable.');

      await cubit.toggleItem(sampleWishlistItem);

      expect(cubit.isFavorite(sampleWishlistItem.productId), isTrue);
      await cubit.close();
    });

    test(
      'clearSession ignores a wishlist response from the old user',
      () async {
        final delay = Completer<void>();
        final repository = _FakeWishlistRepository(
          items: const [sampleWishlistItem],
          loadDelay: delay,
        );
        final cubit = WishlistCubit(_wishlistUseCases(repository));

        final load = cubit.loadWishlistForUser('old-user');
        cubit.clearSession();
        delay.complete();
        await load;

        expect(cubit.state, isEmpty);
        await cubit.close();
      },
    );
  });
}

WishlistUseCases _wishlistUseCases(WishlistRepository repository) {
  return WishlistUseCases(
    getItems: GetWishlistItemsUseCase(repository),
    toggleItem: ToggleWishlistItemUseCase(repository),
  );
}

class _FakeWishlistRepository implements WishlistRepository {
  _FakeWishlistRepository({List<WishlistItem> items = const [], this.loadDelay})
    : _items = List.of(items);

  final List<WishlistItem> _items;
  final Completer<void>? loadDelay;
  Failure? nextFailure;

  Future<ApiResult<List<WishlistItem>>> _result() async {
    if (nextFailure case final failure?) {
      nextFailure = null;
      return ApiResult.failure(failure);
    }

    return ApiResult.success(List.unmodifiable(_items));
  }

  @override
  Future<ApiResult<List<WishlistItem>>> getItems(String userKey) async {
    await loadDelay?.future;
    return _result();
  }

  @override
  Future<ApiResult<List<WishlistItem>>> toggleItem(
    String userKey,
    WishlistItem item,
  ) async {
    final index = _items.indexWhere(
      (entry) => entry.productId == item.productId,
    );
    if (index == -1) {
      _items.add(item);
    } else {
      _items.removeAt(index);
    }

    return _result();
  }
}
