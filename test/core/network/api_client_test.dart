import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_client.dart';
import 'package:yalla_market/core/session/account_inactive_notifier.dart';
import 'package:yalla_market/core/session/session_expired_notifier.dart';
import 'package:yalla_market/core/session/session_metadata.dart';
import 'package:yalla_market/core/storage/token_store.dart';

void main() {
  test(
    'refreshes before access expiry and atomically replaces rotation',
    () async {
      final now = DateTime.now().toUtc();
      final current = _tokens(
        now,
        accessExpiresAt: now.add(const Duration(seconds: 30)),
      );
      final tokenStore = _CountingTokenStore(current);
      var refreshRequests = 0;
      final refreshDio = Dio()
        ..httpClientAdapter = _Adapter((options) {
          refreshRequests += 1;
          expect(options.path, '/auth/refresh');
          expect(options.data, {'refreshToken': 'old-refresh'});
          return _jsonResponse(_refreshPayload(current, now));
        });
      final dio = Dio()
        ..httpClientAdapter = _Adapter((options) {
          expect(options.headers['Authorization'], 'Bearer rotated-access');
          return _jsonResponse({'ok': true});
        });
      final client = ApiClient(
        dio: dio,
        refreshDio: refreshDio,
        tokenStore: tokenStore,
      );

      final payload = await client.get<Map<String, dynamic>>('/protected');

      expect(payload['ok'], isTrue);
      expect(refreshRequests, 1);
      expect(tokenStore.saveCount, 1);
      expect(tokenStore.tokens?.accessToken, 'rotated-access');
      expect(tokenStore.tokens?.refreshToken, 'rotated-refresh');
    },
  );

  test('proactive refresh network failure keeps the saved session', () async {
    final now = DateTime.now().toUtc();
    final current = _tokens(
      now,
      accessExpiresAt: now.add(const Duration(seconds: 30)),
    );
    final tokenStore = _CountingTokenStore(current);
    final notifier = SessionExpiredNotifier();
    var expiredEvents = 0;
    notifier.addListener(() => expiredEvents += 1);
    final refreshDio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      });
    final client = ApiClient(
      dio: Dio()
        ..httpClientAdapter = _Adapter(
          (options) => _jsonResponse({'unexpected': true}),
        ),
      refreshDio: refreshDio,
      tokenStore: tokenStore,
      sessionExpiredNotifier: notifier,
    );

    await expectLater(
      client.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(tokenStore.clearCount, 0);
    expect(tokenStore.tokens, same(current));
    expect(expiredEvents, 0);
  });

  test('concurrent proactive requests share one refresh operation', () async {
    final now = DateTime.now().toUtc();
    final current = _tokens(
      now,
      accessExpiresAt: now.add(const Duration(seconds: 30)),
    );
    final tokenStore = _CountingTokenStore(current);
    final refreshStarted = Completer<void>();
    final refreshResponse = Completer<ResponseBody>();
    var refreshRequests = 0;
    final refreshDio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        refreshRequests += 1;
        if (!refreshStarted.isCompleted) refreshStarted.complete();
        return refreshResponse.future;
      });
    var protectedRequests = 0;
    final dio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        protectedRequests += 1;
        expect(options.headers['Authorization'], 'Bearer rotated-access');
        return _jsonResponse({'request': protectedRequests});
      });
    final client = ApiClient(
      dio: dio,
      refreshDio: refreshDio,
      tokenStore: tokenStore,
    );

    final requests = List.generate(
      3,
      (index) => client.get<Map<String, dynamic>>('/protected/$index'),
    );
    await refreshStarted.future;
    expect(refreshRequests, 1);
    refreshResponse.complete(_jsonResponse(_refreshPayload(current, now)));
    final responses = await Future.wait(requests);

    expect(responses, hasLength(3));
    expect(refreshRequests, 1);
    expect(protectedRequests, 3);
    expect(tokenStore.saveCount, 1);
  });

  test('reactive 401 refreshes and retries the request exactly once', () async {
    final now = DateTime.now().toUtc();
    final current = _tokens(now);
    final tokenStore = _CountingTokenStore(current);
    var protectedRequests = 0;
    final dio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        protectedRequests += 1;
        if (options.headers['Authorization'] == 'Bearer old-access') {
          return _jsonResponse({'code': 'token_not_valid'}, statusCode: 401);
        }
        expect(options.headers['Authorization'], 'Bearer rotated-access');
        return _jsonResponse({'ok': true});
      });
    var refreshRequests = 0;
    final refreshDio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        refreshRequests += 1;
        return _jsonResponse(_refreshPayload(current, now));
      });
    final client = ApiClient(
      dio: dio,
      refreshDio: refreshDio,
      tokenStore: tokenStore,
    );

    final payload = await client.get<Map<String, dynamic>>('/protected');

    expect(payload['ok'], isTrue);
    expect(protectedRequests, 2);
    expect(refreshRequests, 1);
  });

  test(
    'logout sends the latest refresh token after proactive rotation',
    () async {
      final now = DateTime.now().toUtc();
      final current = _tokens(
        now,
        accessExpiresAt: now.add(const Duration(seconds: 30)),
      );
      final tokenStore = _CountingTokenStore(current);
      final refreshDio = Dio()
        ..httpClientAdapter = _Adapter(
          (_) => _jsonResponse(_refreshPayload(current, now)),
        );
      final dio = Dio()
        ..httpClientAdapter = _Adapter((options) {
          expect(options.path, '/auth/logout');
          expect(options.headers['Authorization'], 'Bearer rotated-access');
          expect(options.data, {'refreshToken': 'rotated-refresh'});
          return _jsonResponse({'detail': 'Logout successful.'});
        });
      final client = ApiClient(
        dio: dio,
        refreshDio: refreshDio,
        tokenStore: tokenStore,
      );

      await client.post<Object?>(
        '/auth/logout',
        data: {'refreshToken': 'old-refresh'},
      );

      expect(tokenStore.tokens?.refreshToken, 'rotated-refresh');
    },
  );

  test(
    'a failed retried request does not loop and clears the session',
    () async {
      final now = DateTime.now().toUtc();
      final current = _tokens(now);
      final tokenStore = _CountingTokenStore(current);
      final notifier = SessionExpiredNotifier();
      var expiredEvents = 0;
      notifier.addListener(() => expiredEvents += 1);
      var protectedRequests = 0;
      final dio = Dio()
        ..httpClientAdapter = _Adapter((options) {
          protectedRequests += 1;
          return _jsonResponse({'code': 'token_not_valid'}, statusCode: 401);
        });
      var refreshRequests = 0;
      final refreshDio = Dio()
        ..httpClientAdapter = _Adapter((options) {
          refreshRequests += 1;
          return _jsonResponse(_refreshPayload(current, now));
        });
      final client = ApiClient(
        dio: dio,
        refreshDio: refreshDio,
        tokenStore: tokenStore,
        sessionExpiredNotifier: notifier,
      );

      await expectLater(
        client.get<Map<String, dynamic>>('/protected'),
        throwsA(isA<DioException>()),
      );

      expect(protectedRequests, 2);
      expect(refreshRequests, 1);
      expect(tokenStore.tokens, isNull);
      expect(expiredEvents, 1);
    },
  );

  test('concurrent refresh failure clears and notifies once', () async {
    final now = DateTime.now().toUtc();
    final current = _tokens(
      now,
      accessExpiresAt: now.add(const Duration(seconds: 30)),
    );
    final tokenStore = _CountingTokenStore(current);
    final notifier = SessionExpiredNotifier();
    var expiredEvents = 0;
    notifier.addListener(() => expiredEvents += 1);
    final refreshStarted = Completer<void>();
    final refreshResponse = Completer<ResponseBody>();
    var refreshRequests = 0;
    final refreshDio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        refreshRequests += 1;
        if (!refreshStarted.isCompleted) refreshStarted.complete();
        return refreshResponse.future;
      });
    final dio = Dio()
      ..httpClientAdapter = _Adapter(
        (options) => _jsonResponse({'unexpected': true}),
      );
    final client = ApiClient(
      dio: dio,
      refreshDio: refreshDio,
      tokenStore: tokenStore,
      sessionExpiredNotifier: notifier,
    );

    final requests = List<Future<Object?>>.generate(3, (index) async {
      try {
        await client.get<Map<String, dynamic>>('/protected/$index');
        return null;
      } catch (error) {
        return error;
      }
    });
    await refreshStarted.future;
    refreshResponse.complete(
      _jsonResponse({'code': 'token_not_valid'}, statusCode: 401),
    );
    final results = await Future.wait(requests);

    expect(results, everyElement(isA<DioException>()));
    expect(refreshRequests, 1);
    expect(tokenStore.clearCount, 1);
    expect(tokenStore.tokens, isNull);
    expect(expiredEvents, 1);
  });

  test('skipAuth requests do not attach tokens or refresh', () async {
    final now = DateTime.now().toUtc();
    final tokenStore = _CountingTokenStore(
      _tokens(now, accessExpiresAt: now.subtract(const Duration(minutes: 1))),
    );
    var refreshRequests = 0;
    final dio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        expect(options.headers['Authorization'], isNull);
        return _jsonResponse({'ok': true});
      });
    final refreshDio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        refreshRequests += 1;
        return _jsonResponse({'unexpected': true}, statusCode: 500);
      });
    final client = ApiClient(
      dio: dio,
      refreshDio: refreshDio,
      tokenStore: tokenStore,
    );

    final payload = await client.post<Map<String, dynamic>>(
      '/auth/login/client',
      data: {'identifier': 'm@example.com', 'password': 'wrong'},
      options: Options(extra: const {'skipAuth': true}),
    );

    expect(payload['ok'], isTrue);
    expect(refreshRequests, 0);
  });

  test('account_inactive clears tokens and blocks later requests', () async {
    final tokenStore = _CountingTokenStore(_tokens(DateTime.now().toUtc()));
    final inactiveNotifier = AccountInactiveNotifier();
    var inactiveEvents = 0;
    inactiveNotifier.addListener(() => inactiveEvents += 1);
    var requests = 0;
    final dio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        requests += 1;
        return _jsonResponse({
          'code': 'account_inactive',
          'detail': 'Account inactive.',
        }, statusCode: 403);
      });
    final client = ApiClient(
      dio: dio,
      tokenStore: tokenStore,
      accountInactiveNotifier: inactiveNotifier,
    );

    await expectLater(
      client.get<Object?>('/protected'),
      throwsA(isA<DioException>()),
    );
    await expectLater(
      client.get<Object?>('/another'),
      throwsA(isA<DioException>()),
    );

    expect(tokenStore.tokens, isNull);
    expect(inactiveNotifier.isInactive, isTrue);
    expect(inactiveEvents, 1);
    expect(requests, 1);
  });

  test(
    'inactive client login clears stale tokens without global disable',
    () async {
      final tokenStore = _CountingTokenStore(_tokens(DateTime.now().toUtc()));
      final inactiveNotifier = AccountInactiveNotifier();
      final dio = Dio()
        ..httpClientAdapter = _Adapter(
          (options) =>
              _jsonResponse({'code': 'account_inactive'}, statusCode: 403),
        );
      final client = ApiClient(
        dio: dio,
        tokenStore: tokenStore,
        accountInactiveNotifier: inactiveNotifier,
      );

      await expectLater(
        client.post<Object?>(
          '/auth/login/client',
          data: {'identifier': 'm@example.com', 'password': 'Password123!'},
          options: Options(extra: const {'skipAuth': true}),
        ),
        throwsA(isA<DioException>()),
      );

      expect(tokenStore.tokens, isNull);
      expect(inactiveNotifier.isInactive, isFalse);
    },
  );

  test('account_inactive refresh wins over session-expired handling', () async {
    final now = DateTime.now().toUtc();
    final current = _tokens(
      now,
      accessExpiresAt: now.add(const Duration(seconds: 30)),
    );
    final tokenStore = _CountingTokenStore(current);
    final inactiveNotifier = AccountInactiveNotifier();
    final expiredNotifier = SessionExpiredNotifier();
    var inactiveEvents = 0;
    var expiredEvents = 0;
    inactiveNotifier.addListener(() => inactiveEvents += 1);
    expiredNotifier.addListener(() => expiredEvents += 1);
    final refreshDio = Dio()
      ..httpClientAdapter = _Adapter(
        (options) => _jsonResponse({
          'code': 'account_inactive',
          'detail': 'Account inactive.',
        }, statusCode: 403),
      );
    final client = ApiClient(
      dio: Dio()..httpClientAdapter = _Adapter((_) => _jsonResponse({})),
      refreshDio: refreshDio,
      tokenStore: tokenStore,
      accountInactiveNotifier: inactiveNotifier,
      sessionExpiredNotifier: expiredNotifier,
    );

    await expectLater(
      client.get<Object?>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(tokenStore.tokens, isNull);
    expect(inactiveNotifier.isInactive, isTrue);
    expect(inactiveEvents, 1);
    expect(expiredEvents, 0);
  });

  test('rejects token responses without authoritative session metadata', () {
    expect(
      () => tokensFromApiPayload({
        'accessToken': 'access',
        'refreshToken': 'refresh',
      }),
      throwsA(isA<FormatException>()),
    );
  });
}

StoredAuthTokens _tokens(
  DateTime now, {
  DateTime? accessExpiresAt,
  bool remembered = false,
}) {
  final refreshExpiresAt = now.add(
    remembered ? const Duration(days: 7) : const Duration(hours: 8),
  );
  return StoredAuthTokens(
    accessToken: 'old-access',
    refreshToken: 'old-refresh',
    accessExpiresAt: accessExpiresAt ?? now.add(const Duration(minutes: 10)),
    refreshExpiresAt: refreshExpiresAt,
    sessionStartedAt: now,
    mode: remembered ? AuthSessionMode.persistent : AuthSessionMode.temporary,
    absoluteExpiresAt: remembered ? null : refreshExpiresAt,
  );
}

Map<String, dynamic> _refreshPayload(StoredAuthTokens current, DateTime now) {
  final refreshExpiresAt = current.isRemembered
      ? now.add(const Duration(days: 7))
      : current.absoluteExpiresAt!;
  final normalAccessExpiry = now.add(const Duration(minutes: 15));
  final accessExpiresAt = normalAccessExpiry.isBefore(refreshExpiresAt)
      ? normalAccessExpiry
      : refreshExpiresAt;
  return {
    'accessToken': 'rotated-access',
    'refreshToken': 'rotated-refresh',
    'expiresIn': accessExpiresAt.difference(now).inSeconds,
    'session': {
      'mode': current.mode.wireName,
      'remember': current.isRemembered,
      'startedAt': current.sessionStartedAt.toIso8601String(),
      'absoluteExpiresAt': current.absoluteExpiresAt?.toIso8601String(),
      'accessExpiresAt': accessExpiresAt.toIso8601String(),
      'refreshExpiresAt': refreshExpiresAt.toIso8601String(),
    },
  };
}

ResponseBody _jsonResponse(Object value, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(value),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

final class _CountingTokenStore implements TokenStore {
  _CountingTokenStore(this.tokens);

  StoredAuthTokens? tokens;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<StoredAuthTokens?> read() async => tokens;

  @override
  Future<void> save(StoredAuthTokens value) async {
    saveCount += 1;
    tokens = value;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    tokens = null;
  }
}

final class _Adapter implements HttpClientAdapter {
  _Adapter(this._handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
