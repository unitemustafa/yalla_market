import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/core/network/api_client.dart';
import 'package:yalla_market/core/session/account_inactive_notifier.dart';
import 'package:yalla_market/core/session/session_metadata.dart';
import 'package:yalla_market/core/storage/token_store.dart';

void main() {
  test(
    'successful old-account result cannot be applied after a new login',
    () async {
      final store = InMemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.save(_tokens(now));
      final started = Completer<void>();
      final response = Completer<ResponseBody>();
      final client = ApiClient(
        tokenStore: store,
        dio: Dio()
          ..httpClientAdapter = _Adapter((_) {
            started.complete();
            return response.future;
          }),
      );
      final assertion = expectLater(
        client.get<Object?>('/profile'),
        throwsA(isA<DioException>()),
      );
      await started.future;
      final next = _tokens(now).copyWith(accessToken: 'account-B');
      await store.save(next);
      response.complete(_jsonResponse({'user_id': 'account-A'}));
      await assertion;
      expect(await store.read(), same(next));
    },
  );

  test(
    'inactive response finishing after a new login cannot disable it',
    () async {
      final store = _DelayedClearStore();
      final now = DateTime.now().toUtc();
      await store.save(_tokens(now));
      final notifier = AccountInactiveNotifier();
      final client = ApiClient(
        tokenStore: store,
        accountInactiveNotifier: notifier,
        dio: Dio()
          ..httpClientAdapter = _Adapter(
            (_) => _jsonResponse({'code': 'account_inactive'}, statusCode: 403),
          ),
      );
      final assertion = expectLater(
        client.get<Object?>('/protected'),
        throwsA(isA<DioException>()),
      );
      await store.clearStarted.future;
      final next = _tokens(now).copyWith(accessToken: 'account-B');
      await store.save(next);
      store.finishClear.complete();
      await assertion;
      expect(await store.read(), same(next));
      expect(notifier.isInactive, isFalse);
    },
  );

  test(
    'request session is captured before Dio schedules interceptors',
    () async {
      final now = DateTime.now().toUtc();
      final store = InMemoryTokenStore();
      await store.save(_tokens(now));
      var requests = 0;
      final client = ApiClient(
        tokenStore: store,
        dio: Dio()
          ..httpClientAdapter = _Adapter((_) {
            requests++;
            return _jsonResponse({'ok': true});
          }),
      );
      final request = client.patch<Object?>('/profile', data: {'name': 'A'});
      final assertion = expectLater(request, throwsA(isA<DioException>()));
      await store.clear();
      await store.save(_tokens(now).copyWith(accessToken: 'account-B'));
      await assertion;
      expect(requests, 0);
      expect((await store.read())?.accessToken, 'account-B');
    },
  );

  test('old account request is not replayed for another session', () async {
    final now = DateTime.now().toUtc();
    final current = _tokens(now);
    final store = _CountingTokenStore(current);
    final requestStarted = Completer<void>();
    final firstResponse = Completer<ResponseBody>();
    final sentHeaders = <String>[];
    final client = ApiClient(
      tokenStore: store,
      dio: Dio()
        ..httpClientAdapter = _Adapter((options) {
          sentHeaders.add(options.headers['Authorization'].toString());
          if (sentHeaders.length == 1) {
            requestStarted.complete();
            return firstResponse.future;
          }
          return _jsonResponse({'ok': true});
        }),
      refreshDio: Dio()
        ..httpClientAdapter = _Adapter(
          (_) => throw StateError('No refresh expected'),
        ),
    );
    final request = client.patch<Map<String, dynamic>>(
      '/auth/client/profile/',
      data: {'first_name': 'account-A'},
    );
    await requestStarted.future;
    await store.clear();
    await store.save(
      current.copyWith(
        accessToken: 'account-B-access',
        refreshToken: 'account-B-refresh',
        sessionStartedAt: now.add(const Duration(seconds: 1)),
      ),
    );
    firstResponse.complete(
      _jsonResponse({'detail': 'Expired token'}, statusCode: 401),
    );
    try {
      await request;
    } catch (_) {}
    expect(
      sentHeaders,
      ['Bearer old-access'],
      reason: 'Request prepared in A must not execute with B credentials.',
    );
  });
  test('avatar multipart can survive reactive auth refresh', () async {
    final now = DateTime.now().toUtc();
    final current = _tokens(now);
    final store = _CountingTokenStore(current);
    final client = ApiClient(
      tokenStore: store,
      dio: Dio()
        ..httpClientAdapter = _Adapter(
          (options) => options.headers['Authorization'] == 'Bearer old-access'
              ? _jsonResponse({'detail': 'Expired token'}, statusCode: 401)
              : _jsonResponse({'ok': true}),
        ),
      refreshDio: Dio()
        ..httpClientAdapter = _Adapter(
          (_) => _jsonResponse(_refreshPayload(current, now)),
        ),
    );
    final result = await client.patch<Map<String, dynamic>>(
      '/auth/client/profile/',
      data: FormData.fromMap({
        'avatar': MultipartFile.fromString('bytes', filename: 'avatar.jpg'),
      }),
    );
    expect(result['ok'], isTrue);
  });
  test('refresh cannot restore a cleared session', () async {
    final now = DateTime.now().toUtc();
    final current = _tokens(
      now,
      accessExpiresAt: now.add(const Duration(seconds: 30)),
    );
    final store = _CountingTokenStore(current);
    final refreshStarted = Completer<void>();
    final refreshResponse = Completer<ResponseBody>();
    final client = ApiClient(
      tokenStore: store,
      dio: Dio()
        ..httpClientAdapter = _Adapter((_) => _jsonResponse({'ok': true})),
      refreshDio: Dio()
        ..httpClientAdapter = _Adapter((_) {
          refreshStarted.complete();
          return refreshResponse.future;
        }),
    );
    final request = client.get<Map<String, dynamic>>('/protected');
    await refreshStarted.future;
    await store.clear();
    refreshResponse.complete(_jsonResponse(_refreshPayload(current, now)));
    await expectLater(request, throwsA(isA<DioException>()));
    expect(
      store.tokens,
      isNull,
      reason:
          'A refresh arriving after logout must not persist auth tokens again.',
    );
  });
  test('concurrent cart increments retain all taps', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = CartRepositoryImpl();
    const item = CartItemData(
      id: 'item',
      image: 'x',
      brand: 'x',
      title: 'x',
      price: 10,
      quantity: 1,
    );
    await repository.addItem('user', item, 1);
    await Future.wait([
      repository.incrementQuantity('user', 'item'),
      CartRepositoryImpl().incrementQuantity('user', 'item'),
    ]);
    final result = await repository.getItems('user');
    result.when(
      success: (items) => expect(items.single.quantity, 3),
      failure: (error) => fail(error.message),
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

final class _CountingTokenStore extends TokenStore {
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
    markSessionChanged();
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

final class _DelayedClearStore extends InMemoryTokenStore {
  final clearStarted = Completer<void>();
  final finishClear = Completer<void>();

  @override
  Future<void> clear() async {
    await super.clear();
    clearStarted.complete();
    await finishClear.future;
  }
}
