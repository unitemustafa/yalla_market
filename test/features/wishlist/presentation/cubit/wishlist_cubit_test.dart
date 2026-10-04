import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/domain/usecases/wishlist_usecases.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_state.dart';

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

    test(
      'loaded empty wishlist remains loaded during refresh failure and joins pending refreshes',
      () async {
        final repository = _FakeWishlistRepository();
        final cubit = WishlistCubit(_wishlistUseCases(repository));
        addTearDown(cubit.close);
        expect((cubit.state as WishlistState).hasLoaded, isFalse);
        await cubit.loadWishlistForUser('user');
        expect((cubit.state as WishlistState).hasLoaded, isTrue);
        final delay = Completer<void>();
        repository.loadDelay = delay;
        repository.nextFailure = const ServerFailure('Unavailable');
        final first = cubit.refresh();
        final second = cubit.refresh();
        final loading = cubit.state as WishlistState;
        expect(loading.loading, isTrue);
        expect(loading.hasLoaded, isTrue);
        expect(loading, isEmpty);
        var secondFinished = false;
        second.then((_) => secondFinished = true);
        await Future<void>.delayed(Duration.zero);
        expect(secondFinished, isFalse);
        expect(repository.loadCalls, 2);
        delay.complete();
        await Future.wait([first, second]);
        final failure = cubit.state as WishlistState;
        expect(failure.loading, isFalse);
        expect(failure.hasLoaded, isTrue);
        expect(failure.errorMessage, 'Unavailable');
        expect(failure, isEmpty);
      },
    );

    test(
      'initial wishlist failure ends loading and exposes the error',
      () async {
        final delay = Completer<void>();
        final repository = _FakeWishlistRepository(loadDelay: delay)
          ..nextFailure = const ServerFailure('Unavailable');
        final cubit = WishlistCubit(_wishlistUseCases(repository));
        addTearDown(cubit.close);
        final pending = cubit.loadWishlistForUser('user');
        expect((cubit.state as WishlistState).loading, isTrue);
        delay.complete();
        await pending;
        final failed = cubit.state as WishlistState;
        expect(failed.loading, isFalse);
        expect(failed.hasLoaded, isFalse);
        expect(failed.errorMessage, 'Unavailable');
      },
    );

    test(
      'a new user load does not join the old user operation after a toggle',
      () async {
        final delay = Completer<void>();
        final repository = _FakeWishlistRepository(loadDelay: delay);
        final cubit = WishlistCubit(_wishlistUseCases(repository));
        addTearDown(cubit.close);
        final oldLoad = cubit.loadWishlistForUser('old-user');
        await cubit.toggleItemForUser('new-user', sampleWishlistItem);
        repository.loadDelay = null;
        final newLoad = cubit.loadWishlistForUser('new-user');
        await Future<void>.delayed(Duration.zero);
        expect(repository.loadCalls, 2);
        expect((cubit.state as WishlistState).hasLoaded, isTrue);
        expect(cubit.state.single, sampleWishlistItem);
        delay.complete();
        await Future.wait([oldLoad, newLoad]);
        expect(cubit.state.single, sampleWishlistItem);
      },
    );

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
  Completer<void>? loadDelay;
  int loadCalls = 0;
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
    loadCalls++;
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
