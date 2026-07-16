import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/cache/persistent_json_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores JSON data with freshness metadata', () async {
    const cache = PersistentJsonCache();
    final savedAt = DateTime.utc(2026, 7, 15, 9);

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
