import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/session/session_metadata.dart';
import 'package:yalla_market/core/storage/browser_session_storage_base.dart';
import 'package:yalla_market/core/storage/token_store.dart';

void main() {
  final now = DateTime.utc(2030, 1, 1, 12);

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('StoredAuthTokens', () {
    test('round-trips backend-authoritative session metadata', () {
      final tokens = _tokens(now, remembered: false);

      final decoded = StoredAuthTokens.fromJson(tokens.toJson());

      expect(decoded.accessToken, tokens.accessToken);
      expect(decoded.refreshToken, tokens.refreshToken);
      expect(decoded.mode, AuthSessionMode.temporary);
      expect(decoded.sessionStartedAt, now);
      expect(decoded.absoluteExpiresAt, now.add(const Duration(hours: 8)));
      expect(decoded.sessionDeadline, now.add(const Duration(hours: 8)));
    });

    test('checks access margin separately from the session deadline', () {
      final tokens = _tokens(
        now,
        remembered: false,
        accessExpiresAt: now.add(const Duration(seconds: 30)),
      );

      expect(tokens.accessExpiresSoon(now), isTrue);
      expect(tokens.sessionHasExpired(now), isFalse);
    });

    test('copyWith preserves session identity while replacing both tokens', () {
      final tokens = _tokens(now, remembered: true);

      final copied = tokens.copyWith(
        accessToken: 'next-access',
        refreshToken: 'next-refresh',
        accessExpiresAt: now.add(const Duration(minutes: 20)),
        refreshExpiresAt: now.add(const Duration(days: 8)),
      );

      expect(copied.accessToken, 'next-access');
      expect(copied.refreshToken, 'next-refresh');
      expect(copied.mode, AuthSessionMode.persistent);
      expect(copied.sessionStartedAt, now);
      expect(copied.absoluteExpiresAt, isNull);
    });
  });

  group('SecureTokenStore', () {
    test(
      'persists remembered sessions across mobile process restarts',
      () async {
        const secureStorage = FlutterSecureStorage();
        final firstProcess = SecureTokenStore(
          storage: secureStorage,
          browserSessionStorage: _FakeBrowserSessionStorage(),
          isWeb: false,
        );
        final remembered = _tokens(now, remembered: true);

        await firstProcess.save(remembered);
        final restarted = SecureTokenStore(
          storage: secureStorage,
          browserSessionStorage: _FakeBrowserSessionStorage(),
          isWeb: false,
        );

        expect((await restarted.read())?.refreshToken, remembered.refreshToken);
        expect((await restarted.read())?.isRemembered, isTrue);
      },
    );

    test('keeps temporary mobile sessions in memory only', () async {
      const secureStorage = FlutterSecureStorage();
      final firstProcess = SecureTokenStore(
        storage: secureStorage,
        browserSessionStorage: _FakeBrowserSessionStorage(),
        isWeb: false,
      );
      final temporary = _tokens(now, remembered: false);

      await firstProcess.save(temporary);

      expect(await firstProcess.read(), same(temporary));
      expect(await secureStorage.read(key: 'auth.secure_tokens.v1'), isNull);

      final restarted = SecureTokenStore(
        storage: secureStorage,
        browserSessionStorage: _FakeBrowserSessionStorage(),
        isWeb: false,
      );
      expect(await restarted.read(), isNull);
    });

    test('uses browser session storage for temporary web sessions', () async {
      const secureStorage = FlutterSecureStorage();
      final browserSession = _FakeBrowserSessionStorage();
      final firstTab = SecureTokenStore(
        storage: secureStorage,
        browserSessionStorage: browserSession,
        isWeb: true,
      );
      final temporary = _tokens(now, remembered: false);

      await firstTab.save(temporary);
      final reloadedTab = SecureTokenStore(
        storage: secureStorage,
        browserSessionStorage: browserSession,
        isWeb: true,
      );

      expect((await reloadedTab.read())?.refreshToken, temporary.refreshToken);
      expect(await secureStorage.read(key: 'auth.secure_tokens.v1'), isNull);

      final closedAndReopenedTab = SecureTokenStore(
        storage: secureStorage,
        browserSessionStorage: _FakeBrowserSessionStorage(),
        isWeb: true,
      );
      expect(await closedAndReopenedTab.read(), isNull);
    });

    test(
      'clear removes memory, persistent, and browser session data',
      () async {
        const secureStorage = FlutterSecureStorage();
        final browserSession = _FakeBrowserSessionStorage();
        final store = SecureTokenStore(
          storage: secureStorage,
          browserSessionStorage: browserSession,
          isWeb: true,
        );

        await store.save(_tokens(now, remembered: false));
        await store.clear();

        expect(await store.read(), isNull);
        expect(browserSession.values, isEmpty);
        expect(await secureStorage.read(key: 'auth.secure_tokens.v1'), isNull);
      },
    );
  });

  test('InMemoryTokenStore saves, reads, and clears atomically', () async {
    final store = InMemoryTokenStore();
    final tokens = _tokens(now, remembered: false);

    await store.save(tokens);
    expect(await store.read(), same(tokens));

    await store.clear();
    expect(await store.read(), isNull);
  });
}

StoredAuthTokens _tokens(
  DateTime now, {
  required bool remembered,
  DateTime? accessExpiresAt,
}) {
  final mode = remembered
      ? AuthSessionMode.persistent
      : AuthSessionMode.temporary;
  final refreshExpiresAt = now.add(
    remembered ? const Duration(days: 7) : const Duration(hours: 8),
  );
  return StoredAuthTokens(
    accessToken: 'access-${mode.wireName}',
    refreshToken: 'refresh-${mode.wireName}',
    accessExpiresAt: accessExpiresAt ?? now.add(const Duration(minutes: 15)),
    refreshExpiresAt: refreshExpiresAt,
    sessionStartedAt: now,
    mode: mode,
    absoluteExpiresAt: remembered ? null : refreshExpiresAt,
  );
}

final class _FakeBrowserSessionStorage implements BrowserSessionStorage {
  final Map<String, String> values = {};

  @override
  void delete(String key) => values.remove(key);

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;
}
