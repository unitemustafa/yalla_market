import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../session/account_inactive_notifier.dart';
import '../storage/token_store.dart';

const _pendingAccountDisabledKey = 'push.pending_account_disabled';
const _lastRegisteredTokenKey = 'push.last_registered_token';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  if (message.data['event'] == 'account_disabled') {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_pendingAccountDisabledKey, true);
  }
}

class PushEvent {
  const PushEvent(this.data, {required this.opened});

  final Map<String, dynamic> data;
  final bool opened;
}

class PushNotificationService {
  PushNotificationService(
    this._apiClient,
    this._tokenStore, {
    AccountInactiveNotifier? accountInactiveNotifier,
  }) : _accountInactiveNotifier =
           accountInactiveNotifier ?? AccountInactiveNotifier.instance;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  final AccountInactiveNotifier _accountInactiveNotifier;
  final StreamController<PushEvent> _events =
      StreamController<PushEvent>.broadcast();
  bool _initialized = false;

  Stream<PushEvent> get events => _events.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_pendingAccountDisabledKey) == true) {
      await preferences.remove(_pendingAccountDisabledKey);
      await _disableAccount();
    }
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await Firebase.initializeApp();
      FirebaseMessaging.onMessage.listen(
        (message) => _handleMessage(message, opened: false),
      );
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handleMessage(message, opened: true),
      );
      FirebaseMessaging.instance.onTokenRefresh.listen(_replaceToken);
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage, opened: true);
      }
    } catch (_) {
      // Native Firebase configuration is supplied per deployment. Security
      // still relies on the backend and /auth/me fallback when unavailable.
    }
  }

  Future<void> registerAuthenticatedDevice() async {
    try {
      final tokens = await _tokenStore.read();
      if (tokens == null) return;
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _replaceToken(token);
    } catch (_) {}
  }

  Future<void> unregisterCurrentDevice() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_lastRegisteredTokenKey);
    if (token == null || token.isEmpty) return;
    try {
      await _apiClient.delete<Object?>(
        '/notifications/devices/unregister/',
        data: {'token': token},
        options: Options(extra: const {'allowAfterInactive': true}),
      );
    } catch (_) {
      // Server-side account deactivation also disables every device row.
    } finally {
      await preferences.remove(_lastRegisteredTokenKey);
    }
  }

  Future<void> _replaceToken(String token) async {
    if (await _tokenStore.read() == null) return;
    final preferences = await SharedPreferences.getInstance();
    final previous = preferences.getString(_lastRegisteredTokenKey);
    try {
      await _apiClient.post<Object?>(
        '/notifications/devices/register/',
        data: {
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        },
      );
      await preferences.setString(_lastRegisteredTokenKey, token);
      if (previous != null && previous.isNotEmpty && previous != token) {
        await _apiClient.delete<Object?>(
          '/notifications/devices/unregister/',
          data: {'token': previous},
        );
      }
    } catch (_) {}
  }

  @visibleForTesting
  Future<void> handleTokenRefreshForTesting(String token) =>
      _replaceToken(token);

  void _handleMessage(RemoteMessage message, {required bool opened}) {
    unawaited(
      handleDataForTesting(
        Map<String, dynamic>.from(message.data),
        opened: opened,
      ),
    );
  }

  @visibleForTesting
  Future<void> handleDataForTesting(
    Map<String, dynamic> data, {
    required bool opened,
  }) async {
    if (data['event'] == 'account_disabled') {
      await _disableAccount();
      return;
    }
    _events.add(PushEvent(data, opened: opened));
  }

  Future<void> _disableAccount() async {
    await _tokenStore.clear();
    _accountInactiveNotifier.notifyInactive();
  }
}
