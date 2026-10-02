import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/storage/token_store.dart';

class PendingOrderRequest {
  const PendingOrderRequest({
    required this.userId,
    required this.fingerprint,
    required this.key,
  });

  final String userId;
  final String fingerprint;
  final String key;
}

abstract class PendingOrderRequestStore {
  Future<PendingOrderRequest> prepare(String fingerprint);
  Future<void> complete(PendingOrderRequest request);
}

/// Persists uncertain attempts before sending them, scoped to the signed-in
/// account. Secure storage keeps the checkout fingerprint off plain-text disk.
class SecurePendingOrderRequestStore implements PendingOrderRequestStore {
  SecurePendingOrderRequestStore(
    this._tokenStore, {
    FlutterSecureStorage? storage,
    String Function()? keyFactory,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _keyFactory = keyFactory ?? _newKey;

  final TokenStore _tokenStore;
  final FlutterSecureStorage _storage;
  final String Function() _keyFactory;
  Future<void> _operation = Future.value();

  static String _storageKey(String userId) =>
      'orders.pending_requests.v1.${Uri.encodeComponent(userId)}';

  @override
  Future<PendingOrderRequest> prepare(String fingerprint) =>
      _serialize(() async {
        final userId = await _currentUserId();
        final requests = await _read(userId);
        final existingKey = requests[fingerprint];
        if (existingKey != null) {
          return PendingOrderRequest(
            userId: userId,
            fingerprint: fingerprint,
            key: existingKey,
          );
        }
        final key = _keyFactory();
        requests[fingerprint] = key;
        // A storage failure must stop the POST; generating another key after an
        // uncertain response would otherwise create a second order.
        await _storage.write(
          key: _storageKey(userId),
          value: jsonEncode(requests),
        );
        return PendingOrderRequest(
          userId: userId,
          fingerprint: fingerprint,
          key: key,
        );
      });

  @override
  Future<void> complete(PendingOrderRequest request) => _serialize(() async {
    final requests = await _read(request.userId);
    if (requests[request.fingerprint] != request.key) return;
    requests.remove(request.fingerprint);
    if (requests.isEmpty) {
      await _storage.delete(key: _storageKey(request.userId));
    } else {
      await _storage.write(
        key: _storageKey(request.userId),
        value: jsonEncode(requests),
      );
    }
  });

  Future<Map<String, String>> _read(String userId) async {
    final raw = await _storage.read(key: _storageKey(userId));
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded.values.any(
          (value) =>
              value is! String || !RegExp(r'^[a-f0-9]{32}$').hasMatch(value),
        )) {
      throw const FormatException('Invalid pending order request data.');
    }
    // Corrupt storage fails closed instead of losing an uncertain attempt.
    return decoded.cast<String, String>();
  }

  Future<String> _currentUserId() async {
    final tokens = await _tokenStore.read();
    if (tokens != null) {
      try {
        final parts = tokens.accessToken.split('.');
        if (parts.length == 3) {
          final claims = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );
          if (claims is Map<String, dynamic>) {
            final value = claims['user_id'];
            if (value is String || value is int) {
              final userId = value.toString().trim();
              if (userId.isNotEmpty && userId.length <= 128) return userId;
            }
          }
        }
      } on FormatException {
        // Account identity is used for local isolation, never authorization.
      }
    }
    throw const UnauthorizedFailure('Sign in again before placing an order.');
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _operation.then((_) => action());
    _operation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  static String _newKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
