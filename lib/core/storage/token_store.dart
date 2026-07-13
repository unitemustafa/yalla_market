import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../session/session_metadata.dart';
import 'browser_session_storage.dart';

class StoredAuthTokens {
  const StoredAuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
    required this.sessionStartedAt,
    required this.mode,
    this.absoluteExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;
  final DateTime sessionStartedAt;
  final AuthSessionMode mode;
  final DateTime? absoluteExpiresAt;

  bool get isRemembered => mode.isRemembered;

  DateTime get sessionDeadline => mode == AuthSessionMode.temporary
      ? absoluteExpiresAt ?? refreshExpiresAt
      : refreshExpiresAt;

  bool accessExpiresSoon(
    DateTime now, {
    Duration margin = const Duration(minutes: 1),
  }) {
    return !accessExpiresAt.isAfter(now.add(margin));
  }

  bool sessionHasExpired(DateTime now) => !sessionDeadline.isAfter(now);

  StoredAuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? accessExpiresAt,
    DateTime? refreshExpiresAt,
    DateTime? sessionStartedAt,
    AuthSessionMode? mode,
    Object? absoluteExpiresAt = _notProvided,
  }) {
    return StoredAuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessExpiresAt: accessExpiresAt ?? this.accessExpiresAt,
      refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      mode: mode ?? this.mode,
      absoluteExpiresAt: identical(absoluteExpiresAt, _notProvided)
          ? this.absoluteExpiresAt
          : absoluteExpiresAt as DateTime?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'version': 2,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessExpiresAt': accessExpiresAt.toUtc().toIso8601String(),
      'refreshExpiresAt': refreshExpiresAt.toUtc().toIso8601String(),
      'sessionStartedAt': sessionStartedAt.toUtc().toIso8601String(),
      'sessionMode': mode.wireName,
      'absoluteExpiresAt': absoluteExpiresAt?.toUtc().toIso8601String(),
    };
  }

  factory StoredAuthTokens.fromJson(Map<String, dynamic> json) {
    if (json['sessionMode'] == null) {
      return StoredAuthTokens._fromLegacyJson(json);
    }
    return _validatedTokens(
      StoredAuthTokens(
        accessToken: _requiredString(json, 'accessToken'),
        refreshToken: _requiredString(json, 'refreshToken'),
        accessExpiresAt: _requiredDate(json, 'accessExpiresAt'),
        refreshExpiresAt: _requiredDate(json, 'refreshExpiresAt'),
        sessionStartedAt: _requiredDate(json, 'sessionStartedAt'),
        mode: AuthSessionMode.parse(json['sessionMode']),
        absoluteExpiresAt: _optionalDate(json['absoluteExpiresAt']),
      ),
    );
  }

  factory StoredAuthTokens._fromLegacyJson(Map<String, dynamic> json) {
    final accessToken = _requiredString(json, 'accessToken');
    final refreshToken = _requiredString(json, 'refreshToken');
    final accessPayload = _jwtPayload(accessToken);
    final refreshPayload = _jwtPayload(refreshToken);
    final startedAt = _epochDate(refreshPayload['iat']);
    final legacyDeadline = startedAt.add(const Duration(hours: 8));
    final rawRefreshExpiry = _epochDate(refreshPayload['exp']);

    return _validatedTokens(
      StoredAuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessExpiresAt: _epochDate(accessPayload['exp']),
        refreshExpiresAt: rawRefreshExpiry.isBefore(legacyDeadline)
            ? rawRefreshExpiry
            : legacyDeadline,
        sessionStartedAt: startedAt,
        mode: AuthSessionMode.temporary,
        absoluteExpiresAt: legacyDeadline,
      ),
    );
  }
}

abstract class TokenStore {
  Future<StoredAuthTokens?> read();

  Future<void> save(StoredAuthTokens tokens);

  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({
    FlutterSecureStorage? storage,
    BrowserSessionStorage? browserSessionStorage,
    bool? isWeb,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _browserSessionStorage =
           browserSessionStorage ?? createBrowserSessionStorage(),
       _isWeb = isWeb ?? kIsWeb;

  static const _tokensKey = 'auth.secure_tokens.v1';
  static const _browserSessionKey = 'auth.session_tokens.v1';

  final FlutterSecureStorage _storage;
  final BrowserSessionStorage _browserSessionStorage;
  final bool _isWeb;
  StoredAuthTokens? _sessionTokens;

  @override
  Future<StoredAuthTokens?> read() async {
    if (_sessionTokens case final tokens?) return tokens;

    if (_isWeb) {
      final rawBrowserTokens = _browserSessionStorage.read(_browserSessionKey);
      final browserTokens = _decodeTokens(rawBrowserTokens);
      if (browserTokens != null) {
        _sessionTokens = browserTokens;
        return browserTokens;
      }
      if (rawBrowserTokens != null) {
        _browserSessionStorage.delete(_browserSessionKey);
      }
    }

    final rawTokens = await _storage.read(key: _tokensKey);
    final tokens = _decodeTokens(rawTokens);
    if (tokens == null) {
      if (rawTokens != null) await clear();
      return null;
    }

    if (!tokens.isRemembered) {
      await _storage.delete(key: _tokensKey);
      if (_isWeb) {
        _browserSessionStorage.write(
          _browserSessionKey,
          jsonEncode(tokens.toJson()),
        );
      }
      _sessionTokens = tokens;
    }
    return tokens;
  }

  @override
  Future<void> save(StoredAuthTokens tokens) async {
    final encoded = jsonEncode(tokens.toJson());
    if (!tokens.isRemembered) {
      await _storage.delete(key: _tokensKey);
      if (_isWeb) {
        _browserSessionStorage.write(_browserSessionKey, encoded);
      }
      _sessionTokens = tokens;
      return;
    }

    _browserSessionStorage.delete(_browserSessionKey);
    await _storage.write(key: _tokensKey, value: encoded);
    _sessionTokens = null;
  }

  @override
  Future<void> clear() async {
    _sessionTokens = null;
    _browserSessionStorage.delete(_browserSessionKey);
    await _storage.delete(key: _tokensKey);
  }

  StoredAuthTokens? _decodeTokens(String? rawTokens) {
    if (rawTokens == null || rawTokens.trim().isEmpty) return null;
    try {
      return StoredAuthTokens.fromJson(
        jsonDecode(rawTokens) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}

class InMemoryTokenStore implements TokenStore {
  StoredAuthTokens? _tokens;

  @override
  Future<StoredAuthTokens?> read() async => _tokens;

  @override
  Future<void> save(StoredAuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}

const _notProvided = Object();

StoredAuthTokens _validatedTokens(StoredAuthTokens tokens) {
  if (tokens.mode == AuthSessionMode.temporary &&
      tokens.absoluteExpiresAt == null) {
    throw const FormatException('Missing temporary session deadline.');
  }
  if (tokens.mode == AuthSessionMode.persistent &&
      tokens.absoluteExpiresAt != null) {
    throw const FormatException('Persistent session has an absolute deadline.');
  }
  if (tokens.accessExpiresAt.isAfter(tokens.sessionDeadline) ||
      tokens.refreshExpiresAt.isAfter(tokens.sessionDeadline) ||
      tokens.sessionStartedAt.isAfter(tokens.sessionDeadline)) {
    throw const FormatException('Invalid authentication session timestamps.');
  }
  return tokens;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Missing $key.');
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = _optionalDate(json[key]);
  if (value != null) return value;
  throw FormatException('Missing $key.');
}

DateTime? _optionalDate(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}

Map<String, dynamic> _jwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) throw const FormatException('Invalid JWT.');
  final bytes = base64Url.decode(base64Url.normalize(parts[1]));
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

DateTime _epochDate(Object? value) {
  final seconds = switch (value) {
    int number => number,
    num number => number.toInt(),
    String text => int.tryParse(text),
    _ => null,
  };
  if (seconds == null) throw const FormatException('Invalid JWT timestamp.');
  return DateTime.fromMillisecondsSinceEpoch(
    seconds * Duration.millisecondsPerSecond,
    isUtc: true,
  );
}
