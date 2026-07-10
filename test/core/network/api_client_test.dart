import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_client.dart';
import 'package:yalla_market/core/session/session_expired_notifier.dart';
import 'package:yalla_market/core/session/account_inactive_notifier.dart';
import 'package:yalla_market/core/storage/token_store.dart';

void main() {
  test('clears tokens and notifies when refresh recovery fails', () async {
    final tokenStore = InMemoryTokenStore();
    await tokenStore.save(
      StoredAuthTokens(
        accessToken: 'expired-access',
        refreshToken: 'expired-refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    final notifier = SessionExpiredNotifier();
    var expirationEvents = 0;
    notifier.addListener(() => expirationEvents += 1);

    final dio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        return ResponseBody.fromString(
          '{"message":"Unauthorized"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final refreshDio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        expect(options.path, '/auth/refresh');
        return ResponseBody.fromString(
          '{"message":"Refresh token expired"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
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

    expect(await tokenStore.read(), isNull);
    expect(expirationEvents, 1);
  });

  test('skipAuth requests do not attach tokens or refresh', () async {
    final tokenStore = InMemoryTokenStore();
    await tokenStore.save(
      StoredAuthTokens(
        accessToken: 'saved-access',
        refreshToken: 'saved-refresh',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );

    var refreshRequests = 0;
    final dio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        expect(options.headers[Headers.wwwAuthenticateHeader], isNull);
        expect(options.headers['Authorization'], isNull);
        return ResponseBody.fromString(
          '{"ok":true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final refreshDio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        refreshRequests += 1;
        return ResponseBody.fromString(
          '{"message":"Should not refresh"}',
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final client = ApiClient(
      dio: dio,
      refreshDio: refreshDio,
      tokenStore: tokenStore,
    );

    final payload = await client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': 'm@example.com', 'password': 'wrong'},
      options: Options(extra: const {'skipAuth': true}),
    );

    expect(payload['ok'], isTrue);
    expect(refreshRequests, 0);
  });

  test(
    'account_inactive clears tokens, notifies, and blocks later requests',
    () async {
      final tokenStore = InMemoryTokenStore();
      await tokenStore.save(
        StoredAuthTokens(
          accessToken: 'active-access',
          refreshToken: 'active-refresh',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      final inactiveNotifier = AccountInactiveNotifier();
      var inactiveEvents = 0;
      inactiveNotifier.addListener(() => inactiveEvents += 1);
      var requests = 0;
      final dio = Dio()
        ..httpClientAdapter = _Adapter((options) {
          requests += 1;
          return ResponseBody.fromString(
            '{"code":"account_inactive","detail":"تم إيقاف حسابك. تواصل مع الدعم."}',
            403,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
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

      expect(await tokenStore.read(), isNull);
      expect(inactiveNotifier.isInactive, isTrue);
      expect(inactiveEvents, 1);
      expect(requests, 1);
    },
  );

  test('account_inactive refresh does not emit session expired', () async {
    final tokenStore = InMemoryTokenStore();
    await tokenStore.save(
      StoredAuthTokens(
        accessToken: 'expired-access',
        refreshToken: 'active-refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    final inactiveNotifier = AccountInactiveNotifier();
    final expiredNotifier = SessionExpiredNotifier();
    var inactiveEvents = 0;
    var expiredEvents = 0;
    inactiveNotifier.addListener(() => inactiveEvents += 1);
    expiredNotifier.addListener(() => expiredEvents += 1);
    final dio = Dio()
      ..httpClientAdapter = _Adapter(
        (_) => ResponseBody.fromString(
          '{"detail":"Token is invalid"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
    final refreshDio = Dio()
      ..httpClientAdapter = _Adapter(
        (_) => ResponseBody.fromString(
          '{"code":"account_inactive","detail":"تم إيقاف حسابك. تواصل مع الدعم."}',
          403,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
    final client = ApiClient(
      dio: dio,
      refreshDio: refreshDio,
      tokenStore: tokenStore,
      accountInactiveNotifier: inactiveNotifier,
      sessionExpiredNotifier: expiredNotifier,
    );

    await expectLater(
      client.get<Object?>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(await tokenStore.read(), isNull);
    expect(inactiveNotifier.isInactive, isTrue);
    expect(inactiveEvents, 1);
    expect(expiredEvents, 0);
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;

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
