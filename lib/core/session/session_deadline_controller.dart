import 'dart:async';

import '../storage/token_store.dart';
import 'session_expired_notifier.dart';

typedef SessionNow = DateTime Function();
typedef SessionTimerFactory =
    Timer Function(Duration duration, void Function() callback);

class SessionDeadlineController {
  SessionDeadlineController({
    required TokenStore tokenStore,
    SessionExpiredNotifier? sessionExpiredNotifier,
    SessionNow? now,
    SessionTimerFactory? timerFactory,
  }) : _tokenStore = tokenStore,
       _sessionExpiredNotifier =
           sessionExpiredNotifier ?? SessionExpiredNotifier.instance,
       _now = now ?? DateTime.now,
       _timerFactory = timerFactory ?? _createTimer;

  final TokenStore _tokenStore;
  final SessionExpiredNotifier _sessionExpiredNotifier;
  final SessionNow _now;
  final SessionTimerFactory _timerFactory;

  Timer? _deadlineTimer;
  String? _activeSessionKey;
  String? _expiredSessionKey;
  Future<void>? _expirationInFlight;

  Future<bool> activate(StoredAuthTokens tokens) async {
    final key = tokens.refreshToken;
    if (tokens.sessionHasExpired(_now())) {
      _activeSessionKey = key;
      await expireSession();
      return false;
    }

    if (_activeSessionKey == key && _deadlineTimer?.isActive == true) {
      return true;
    }

    _deadlineTimer?.cancel();
    _activeSessionKey = key;
    _expiredSessionKey = null;
    final delay = tokens.sessionDeadline.difference(_now());
    final generation = _tokenStore.sessionGeneration;
    _deadlineTimer = _timerFactory(delay, () {
      if (_tokenStore.sessionGeneration == generation) {
        unawaited(expireSession());
      }
    });
    return true;
  }

  Future<bool> validateCurrentSession() async {
    final generation = _tokenStore.sessionGeneration;
    final tokens = await _tokenStore.read();
    if (tokens == null || generation != _tokenStore.sessionGeneration) {
      return false;
    }
    return activate(tokens);
  }

  Future<void> expireSession() async {
    final pending = _expirationInFlight;
    if (pending != null) return pending;
    if (_activeSessionKey != null && _expiredSessionKey == _activeSessionKey) {
      return;
    }

    final operation = () async {
      final generation = _tokenStore.sessionGeneration;
      _deadlineTimer?.cancel();
      _deadlineTimer = null;
      _expiredSessionKey = _activeSessionKey;
      if (await _tokenStore.clearIfCurrent(generation)) {
        _sessionExpiredNotifier.notifyExpired();
      }
    }();
    _expirationInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_expirationInFlight, operation)) {
        _expirationInFlight = null;
      }
    }
  }

  Future<void> clearSession() async {
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
    _activeSessionKey = null;
    _expiredSessionKey = null;
    await _tokenStore.clear();
  }

  void dispose() {
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
  }
}

Timer _createTimer(Duration duration, void Function() callback) {
  return Timer(duration, callback);
}
