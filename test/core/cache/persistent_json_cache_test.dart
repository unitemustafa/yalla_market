import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/cache/persistent_json_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores JSON data with freshness metadata', () async {
    final savedAt = DateTime.utc(2026, 7, 15, 9);
    final cache = PersistentJsonCache(now: () => savedAt);

    await cache.write('products.cairo', const {
      'results': [
        {'id': 1, 'name': 'Product'},
      ],
    }, savedAt: savedAt);

    final entry = await cache.read('products.cairo');
    expect(entry, isNotNull);
    expect(entry!.savedAt, savedAt);
    expect(entry.isFresh(const Duration(minutes: 30), now: savedAt), isTrue);
    expect(
      entry.isFresh(
        const Duration(minutes: 30),
        now: savedAt.add(const Duration(hours: 1)),
      ),
      isFalse,
    );
  });

  test(
    'evicts oldest entries, expires stale data and skips oversized entries',
    () async {
      var time = DateTime.utc(2030);
      final cache = PersistentJsonCache(
        maxEntries: 2,
        maxEntryCharacters: 200,
        now: () => time,
      );
      await cache.write('a', {'id': 1});
      time = time.add(const Duration(seconds: 1));
      await cache.write('b', {'id': 2});
      await cache.write('c', {'id': 3});
      expect(await cache.read('a'), isNull);
      expect(await cache.read('b'), isNotNull);
      await cache.write('huge', {'value': List.filled(500, 'x').join()});
      expect(await cache.read('huge'), isNull);
      time = time.add(const Duration(days: 8));
      expect(await cache.read('b'), isNull);
    },
  );

  test('removes malformed cache entries safely', () async {
    SharedPreferences.setMockInitialValues({
      'catalog_cache.v1.products.cairo': '{broken',
    });
    const cache = PersistentJsonCache();

    expect(await cache.read('products.cairo'), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('catalog_cache.v1.products.cairo'), isFalse);
  });
}
