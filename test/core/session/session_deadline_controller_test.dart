import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/session/session_deadline_controller.dart';
import 'package:yalla_market/core/session/session_expired_notifier.dart';
import 'package:yalla_market/core/session/session_metadata.dart';
import 'package:yalla_market/core/storage/token_store.dart';

void main() {
  test('temporary session logs out at the exact eight-hour deadline', () {
    fakeAsync((async) {
      final base = DateTime.utc(2030, 1, 1, 8);
      final store = _TestTokenStore();
      final notifier = SessionExpiredNotifier();
      var expiredEvents = 0;
      notifier.addListener(() => expiredEvents += 1);
      final controller = SessionDeadlineController(
        tokenStore: store,
        sessionExpiredNotifier: notifier,
        now: () => base.add(async.elapsed),
      );
      final tokens = _temporaryTokens(base);
      store.save(tokens);
      controller.activate(tokens);
      async.flushMicrotasks();

      async.elapse(const Duration(hours: 7, minutes: 59));
      async.flushMicrotasks();
      expect(store.tokens, isNotNull);
      expect(expiredEvents, 0);

      async.elapse(const Duration(minutes: 1));
      async.flushMicrotasks();
      expect(store.tokens, isNull);
      expect(expiredEvents, 1);

      controller.dispose();
    });
  });

  test('persistent token rotation rearms the sliding inactivity deadline', () {
    fakeAsync((async) {
      final base = DateTime.utc(2030, 1, 1, 8);
      final store = _TestTokenStore();
      final notifier = SessionExpiredNotifier();
      var expiredEvents = 0;
      notifier.addListener(() => expiredEvents += 1);
      final controller = SessionDeadlineController(
        tokenStore: store,
        sessionExpiredNotifier: notifier,
        now: () => base.add(async.elapsed),
      );
      final first = _persistentTokens(base, refreshToken: 'first-refresh');
      store.save(first);
      controller.activate(first);
      async.flushMicrotasks();

      async.elapse(const Duration(days: 6));
      final refreshedAt = base.add(async.elapsed);
      final rotated = _persistentTokens(
        base,
        refreshToken: 'rotated-refresh',
        refreshExpiresAt: refreshedAt.add(const Duration(days: 7)),
      );
      store.save(rotated);
      controller.activate(rotated);
      async.flushMicrotasks();

      async.elapse(const Duration(days: 1));
      async.flushMicrotasks();
      expect(store.tokens, isNotNull);
      expect(expiredEvents, 0);

      async.elapse(const Duration(days: 6));
      async.flushMicrotasks();
      expect(store.tokens, isNull);
      expect(expiredEvents, 1);

      controller.dispose();
    });
  });

  test('already expired sessions are cleared and notified once', () {
    fakeAsync((async) {
      final now = DateTime.utc(2030, 1, 1, 16);
      final store = _TestTokenStore();
      final notifier = SessionExpiredNotifier();
      var expiredEvents = 0;
      notifier.addListener(() => expiredEvents += 1);
      final controller = SessionDeadlineController(
        tokenStore: store,
        sessionExpiredNotifier: notifier,
        now: () => now,
      );
      final expired = _temporaryTokens(now.subtract(const Duration(hours: 8)));
      store.save(expired);
      bool? usable;
      controller.activate(expired).then((value) => usable = value);
      async.flushMicrotasks();

      expect(usable, isFalse);
      expect(store.tokens, isNull);
      expect(expiredEvents, 1);

      controller.expireSession();
      async.flushMicrotasks();
      expect(expiredEvents, 1);
      controller.dispose();
    });
  });
}

StoredAuthTokens _temporaryTokens(DateTime startedAt) {
  final deadline = startedAt.add(const Duration(hours: 8));
  return StoredAuthTokens(
    accessToken: 'temporary-access',
    refreshToken: 'temporary-refresh',
    accessExpiresAt: startedAt.add(const Duration(minutes: 15)),
    refreshExpiresAt: deadline,
    sessionStartedAt: startedAt,
    mode: AuthSessionMode.temporary,
    absoluteExpiresAt: deadline,
  );
}

StoredAuthTokens _persistentTokens(
  DateTime startedAt, {
  required String refreshToken,
  DateTime? refreshExpiresAt,
}) {
  return StoredAuthTokens(
    accessToken: 'persistent-access',
    refreshToken: refreshToken,
    accessExpiresAt: startedAt.add(const Duration(minutes: 15)),
    refreshExpiresAt:
        refreshExpiresAt ?? startedAt.add(const Duration(days: 7)),
    sessionStartedAt: startedAt,
    mode: AuthSessionMode.persistent,
  );
}

final class _TestTokenStore implements TokenStore {
  StoredAuthTokens? tokens;

  @override
  Future<StoredAuthTokens?> read() async => tokens;

  @override
  Future<void> save(StoredAuthTokens value) async {
    tokens = value;
  }

  @override
  Future<void> clear() async {
    tokens = null;
  }
}
