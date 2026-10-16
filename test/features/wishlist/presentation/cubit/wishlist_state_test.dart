import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_state.dart';

void main() {
  test('membership is indexed once for a large immutable snapshot', () {
    var idReads = 0;
    final state = WishlistState(
      List.generate(1000, (index) => _CountedItem('$index', () => idReads++)),
    );
    expect(state.containsProduct('999'), isTrue);
    final readsAfterIndex = idReads;
    for (var index = 0; index < 1000; index++) {
      expect(state.containsProduct('$index'), isTrue);
      expect(state.containsProduct('missing'), isFalse);
    }
    expect(readsAfterIndex, 1000);
    expect(idReads, readsAfterIndex);
  });

  test(
    'membership retains the copied snapshot and updates with a new state',
    () {
      final source = [_item('one')];
      final original = WishlistState(source);
      expect(original.containsProduct('one'), isTrue);
      source.clear();
      source.add(_item('two'));
      final refreshed = WishlistState(source);
      expect(original.containsProduct('one'), isTrue);
      expect(original.containsProduct('two'), isFalse);
      expect(refreshed.containsProduct('one'), isFalse);
      expect(refreshed.containsProduct('two'), isTrue);
      expect(() => original.add(_item('three')), throwsUnsupportedError);
      expect(WishlistState([]).containsProduct('one'), isFalse);
    },
  );
}

WishlistItem _item(String id) =>
    WishlistItem(productId: id, image: '', title: id, brand: '', price: '10');

class _CountedItem extends WishlistItem {
  _CountedItem(this.id, this.onRead)
    : super(productId: id, image: '', title: id, brand: '', price: '10');
  final String id;
  final void Function() onRead;
  @override
  String get productId {
    onRead();
    return id;
  }
}
