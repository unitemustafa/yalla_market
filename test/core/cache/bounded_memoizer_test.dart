import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/cache/bounded_memoizer.dart';

void main() {
  group('BoundedMemoizer', () {
    test(
      'Given a full cache, when a key is recently read, then it is retained',
      () {
        final memoizer = BoundedMemoizer<String, String>(capacity: 2);
        var computes = 0;

        String resolve(String key) => memoizer.resolve(key, () {
          computes++;
          return '$key-$computes';
        });

        expect(resolve('a'), 'a-1');
        expect(resolve('b'), 'b-2');
        expect(resolve('a'), 'a-1');
        expect(resolve('c'), 'c-3');

        expect(resolve('a'), 'a-1');
        expect(resolve('b'), 'b-4');
      },
    );

    test(
      'Given caching is bypassed, when resolving, then the stored value survives',
      () {
        final memoizer = BoundedMemoizer<String, String>(capacity: 1);
        var computes = 0;

        String next() => 'value-${++computes}';

        expect(memoizer.resolve('price', next), 'value-1');
        expect(memoizer.resolve('price', next, cache: false), 'value-2');
        expect(memoizer.resolve('price', next), 'value-1');
      },
    );

    test(
      'Given computation throws, when resolving, then valid cached entries remain',
      () {
        final memoizer = BoundedMemoizer<String, String>(capacity: 1);
        expect(memoizer.resolve('valid', () => 'stable'), 'stable');
        expect(
          () => memoizer.resolve('broken', () => throw StateError('bad')),
          throwsStateError,
        );
        expect(memoizer.resolve('valid', () => 'replacement'), 'stable');
      },
    );

    test(
      'Given explicit entries, when cleared, then no stale value is reused',
      () {
        final memoizer = BoundedMemoizer<String, String>(capacity: 2);

        memoizer.store('category', 'old');
        expect(memoizer.lookup('category'), 'old');
        memoizer.clear();

        expect(memoizer.lookup('category'), isNull);
      },
    );

    test(
      'Given a non-positive capacity, when constructing, then it is rejected',
      () {
        expect(
          () => BoundedMemoizer<String, String>(capacity: 0),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });
}
