import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/cache/data_freshness.dart';

void main() {
  test('is stale until a network success and again at the exact max age', () {
    var now = DateTime.utc(2030, 1, 1, 12);
    final freshness = DataFreshness(now: () => now);

    expect(freshness.isStale, isTrue);

    freshness.markNetworkSuccess();
    now = now.add(const Duration(seconds: 59));
    expect(freshness.isStale, isFalse);

    now = now.add(const Duration(seconds: 1));
    expect(freshness.isStale, isTrue);
  });

  test('invalidate clears a successful network timestamp', () {
    final freshness = DataFreshness(now: () => DateTime.utc(2030));

    freshness.markNetworkSuccess();
    freshness.invalidate();

    expect(freshness.lastNetworkSuccessAt, isNull);
    expect(freshness.isStale, isTrue);
  });

  test('does not accept a network success started before invalidation', () {
    final freshness = DataFreshness(now: () => DateTime.utc(2030));
    final requestRevision = freshness.revision;

    freshness.invalidate();
    freshness.markNetworkSuccess(revision: requestRevision);

    expect(freshness.revision, requestRevision + 1);
    expect(freshness.lastNetworkSuccessAt, isNull);
    expect(freshness.isStale, isTrue);
  });
}
