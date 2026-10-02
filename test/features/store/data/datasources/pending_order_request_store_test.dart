import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/session/session_metadata.dart';
import 'package:yalla_market/core/storage/token_store.dart';
import 'package:yalla_market/features/store/data/datasources/pending_order_request_store.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    _nextKey = 0;
  });

  test('uncertain attempt survives a new store and token rotation', () async {
    final tokens = InMemoryTokenStore();
    await tokens.save(_tokens('1'));
    final first = await _store(tokens).prepare('basket');
    await tokens.save(_tokens('1', rotated: true));
    final restarted = await _store(tokens).prepare('basket');

    expect(restarted.key, first.key);
    expect(first.key, matches(RegExp(r'^[a-f0-9]{32}$')));
  });

  test(
    'account switch isolates attempts and switching back recovers them',
    () async {
      final tokens = InMemoryTokenStore();
      final store = _store(tokens);
      await tokens.save(_tokens('1'));
      final first = await store.prepare('basket');
      await tokens.save(_tokens('2'));
      final other = await store.prepare('basket');
      expect(other.key, isNot(first.key));
      await tokens.save(_tokens('1'));
      expect((await store.prepare('basket')).key, first.key);
    },
  );

  test(
    'editing a basket does not erase an earlier uncertain attempt',
    () async {
      final tokens = InMemoryTokenStore();
      await tokens.save(_tokens('1'));
      final store = _store(tokens);
      final original = await store.prepare('original');
      final edited = await store.prepare('edited');
      expect(edited.key, isNot(original.key));
      expect((await store.prepare('original')).key, original.key);
    },
  );

  test(
    'confirmed order allows a new intentional order with the same basket',
    () async {
      final tokens = InMemoryTokenStore();
      await tokens.save(_tokens('1'));
      final store = _store(tokens);
      final first = await store.prepare('basket');
      await store.complete(first);
      expect((await store.prepare('basket')).key, isNot(first.key));
    },
  );

  test(
    'concurrent preparations share a key without losing other baskets',
    () async {
      final tokens = InMemoryTokenStore();
      await tokens.save(_tokens('1'));
      final store = _store(tokens);
      final requests = await Future.wait([
        store.prepare('basket'),
        store.prepare('basket'),
        store.prepare('other'),
      ]);
      expect(requests[0].key, requests[1].key);
      expect(requests[2].key, isNot(requests[0].key));
      await store.complete(requests[0]);
      expect((await store.prepare('other')).key, requests[2].key);
    },
  );

  test(
    'completion after switching accounts clears only the original account',
    () async {
      final tokens = InMemoryTokenStore();
      await tokens.save(_tokens('1'));
      final store = _store(tokens);
      final first = await store.prepare('basket');
      await tokens.save(_tokens('2'));
      final other = await store.prepare('basket');
      await store.complete(first);
      expect((await store.prepare('basket')).key, other.key);
    },
  );

  test(
    'missing or invalid account identity fails before making a new key',
    () async {
      final tokens = InMemoryTokenStore();
      final store = _store(tokens);
      await expectLater(
        store.prepare('basket'),
        throwsA(isA<UnauthorizedFailure>()),
      );
      await tokens.save(_tokens('1', invalid: true));
      await expectLater(
        store.prepare('basket'),
        throwsA(isA<UnauthorizedFailure>()),
      );
    },
  );

  test(
    'corrupt persisted attempts fail closed instead of replacing the key',
    () async {
      for (final raw in ['invalid-json', '[]', '{"basket": "invalid-key"}']) {
        FlutterSecureStorage.setMockInitialValues({
          'orders.pending_requests.v1.1': raw,
        });
        final tokens = InMemoryTokenStore();
        await tokens.save(_tokens('1'));
        await expectLater(
          _store(tokens).prepare('basket'),
          throwsA(isA<FormatException>()),
        );
      }
    },
  );
}

int _nextKey = 0;

SecurePendingOrderRequestStore _store(TokenStore tokens) =>
    SecurePendingOrderRequestStore(
      tokens,
      keyFactory: () => (++_nextKey).toRadixString(16).padLeft(32, '0'),
    );

StoredAuthTokens _tokens(
  String userId, {
  bool rotated = false,
  bool invalid = false,
}) {
  final claims = base64Url.encode(utf8.encode(jsonEncode({'user_id': userId})));
  return StoredAuthTokens(
    accessToken: invalid
        ? 'invalid-token'
        : 'header.$claims.${rotated ? 'rotated' : 'signature'}',
    refreshToken: 'test-refresh',
    accessExpiresAt: DateTime.utc(2030, 1, 1, 1),
    refreshExpiresAt: DateTime.utc(2030, 2, 1),
    sessionStartedAt: DateTime.utc(2030, 1, 1),
    mode: AuthSessionMode.persistent,
  );
}
