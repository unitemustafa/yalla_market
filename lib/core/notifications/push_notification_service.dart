import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../session/account_inactive_notifier.dart';
import '../session/account_restored_notifier.dart';
import '../preferences/app_preferences_controller.dart';
import '../storage/token_store.dart';
import '../../firebase_options.dart';
import 'account_notification_presenter.dart';

export 'account_notification_presenter.dart';

const _pendingAccountDisabledKey = 'push.pending_account_disabled';
const _lastRegisteredTokenKey = 'push.last_registered_token';

bool get pushNotificationsSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    _debugPushError('background initialization', error, stackTrace);
  }
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
    AccountRestoredNotifier? accountRestoredNotifier,
    AccountNotificationPresenter? accountNotificationPresenter,
  }) : _accountInactiveNotifier =
           accountInactiveNotifier ?? AccountInactiveNotifier.instance,
       _accountRestoredNotifier =
           accountRestoredNotifier ?? AccountRestoredNotifier.instance,
       _accountNotificationPresenter =
           accountNotificationPresenter ??
           FlutterAccountNotificationPresenter();

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  final AccountInactiveNotifier _accountInactiveNotifier;
  final AccountRestoredNotifier _accountRestoredNotifier;
  final AccountNotificationPresenter _accountNotificationPresenter;
  final StreamController<PushEvent> _events =
      StreamController<PushEvent>.broadcast();
  final Set<String> _displayedRestoredNotifications = <String>{};
  final Set<String> _openedRestoredNotifications = <String>{};
  final Set<String> _displayedDeliveryAreaNotifications = <String>{};
  final Set<String> _displayedMarketNotifications = <String>{};
  final Set<String> _displayedProductNotifications = <String>{};
  final Set<String> _displayedOfferNotifications = <String>{};
  final Set<String> _displayedPartnerNotifications = <String>{};
  final List<PushEvent> _pendingInitialOpenedEvents = <PushEvent>[];
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  Future<void>? _initialization;

  Stream<PushEvent> get events => _events.stream;

  List<PushEvent> takePendingInitialOpenedEvents() {
    final pending = List<PushEvent>.from(_pendingInitialOpenedEvents);
    _pendingInitialOpenedEvents.clear();
    return pending;
  }

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_pendingAccountDisabledKey) == true) {
      await preferences.remove(_pendingAccountDisabledKey);
      await _disableAccount();
    }
    if (!pushNotificationsSupported) return;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      try {
        await _accountNotificationPresenter.initialize(
          (data) => handleDataForTesting(data, opened: true),
        );
      } catch (error, stackTrace) {
        _debugPushError('local notification initialization', error, stackTrace);
      }
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
        (message) => _handleMessage(message, opened: false),
      );
      _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handleMessage(message, opened: true),
      );
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen(_replaceToken);
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage, opened: true, queueForAppStart: true);
      }
    } catch (error, stackTrace) {
      // Native Firebase configuration is supplied per deployment. Security
      // still relies on the backend and /auth/me fallback when unavailable.
      _debugPushError('initialization', error, stackTrace);
    }
  }

  Future<void> registerAuthenticatedDevice() async {
    await initialize();
    if (!pushNotificationsSupported) return;
    if (!AppPreferencesController.instance.mobileNotificationsEnabled) return;
    try {
      final tokens = await _tokenStore.read();
      if (tokens == null) return;
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      try {
        await _accountNotificationPresenter.requestPermission();
      } catch (error, stackTrace) {
        _debugPushError('local notification permission', error, stackTrace);
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _replaceToken(token);
    } catch (error, stackTrace) {
      _debugPushError('device registration', error, stackTrace);
    }
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
    } catch (error, stackTrace) {
      _debugPushError('device unregistration', error, stackTrace);
    } finally {
      await preferences.remove(_lastRegisteredTokenKey);
    }
  }

  Future<void> _replaceToken(String token) async {
    if (!AppPreferencesController.instance.mobileNotificationsEnabled) return;
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
    } catch (error, stackTrace) {
      _debugPushError('token replacement', error, stackTrace);
    }
  }

  @visibleForTesting
  Future<void> handleTokenRefreshForTesting(String token) =>
      _replaceToken(token);

  void _handleMessage(
    RemoteMessage message, {
    required bool opened,
    bool queueForAppStart = false,
  }) {
    final data = Map<String, dynamic>.from(message.data);
    if (message.messageId != null) {
      data['_fcm_message_id'] = message.messageId;
    }
    unawaited(
      handleDataForTesting(
        data,
        opened: opened,
        queueForAppStart: queueForAppStart,
      ),
    );
  }

  @visibleForTesting
  Future<void> handleDataForTesting(
    Map<String, dynamic> data, {
    required bool opened,
    bool queueForAppStart = false,
  }) async {
    final event = data['event']?.toString();
    if (event == 'account_disabled') {
      await _disableAccount();
      return;
    }
    if (event == 'account_restored') {
      await _handleAccountRestored(
        data,
        opened: opened,
        queueForAppStart: queueForAppStart,
      );
      return;
    }
    if (event == 'delivery_area_created' && !opened) {
      final key = _deliveryAreaNotificationKey(data);
      if (_displayedDeliveryAreaNotifications.add(key)) {
        try {
          await _accountNotificationPresenter.showDeliveryAreaCreated(data);
        } catch (error, stackTrace) {
          _debugPushError('delivery-area display', error, stackTrace);
        }
      }
    }
    if (event == 'market_created' && !opened) {
      final key = _marketNotificationKey(data);
      if (_displayedMarketNotifications.add(key)) {
        try {
          await _accountNotificationPresenter.showMarketCreated(data);
        } catch (error, stackTrace) {
          _debugPushError('market-created display', error, stackTrace);
        }
      }
    }
    if (event == 'product_created' && !opened) {
      final key = _productNotificationKey(data);
      if (_displayedProductNotifications.add(key)) {
        try {
          await _accountNotificationPresenter.showProductCreated(data);
        } catch (error, stackTrace) {
          _debugPushError('product-created display', error, stackTrace);
        }
      }
    }
    if (event == 'offer_created' && !opened) {
      final key = _offerNotificationKey(data);
      if (_displayedOfferNotifications.add(key)) {
        try {
          await _accountNotificationPresenter.showOfferCreated(data);
        } catch (error, stackTrace) {
          _debugPushError('offer-created display', error, stackTrace);
        }
      }
    }
    if (event == 'partner_application_approved' && !opened) {
      final key = _partnerNotificationKey(data);
      if (_displayedPartnerNotifications.add(key)) {
        try {
          await _accountNotificationPresenter.showPartnerApplicationApproved(
            data,
          );
        } catch (error, stackTrace) {
          _debugPushError('partner-approved display', error, stackTrace);
        }
      }
    }
    _events.add(PushEvent(data, opened: opened));
  }

  String _offerNotificationKey(Map<String, dynamic> data) {
    final notificationId = data['notification_id']?.toString().trim();
    if (notificationId != null && notificationId.isNotEmpty) {
      return 'notification:$notificationId';
    }
    final messageId = data['_fcm_message_id']?.toString().trim();
    if (messageId != null && messageId.isNotEmpty) {
      return 'message:$messageId';
    }
    return 'offer:${data['offer_id']}:${data['dispatch_id']}';
  }

  String _productNotificationKey(Map<String, dynamic> data) {
    final notificationId = data['notification_id']?.toString().trim();
    if (notificationId != null && notificationId.isNotEmpty) {
      return 'notification:$notificationId';
    }
    final messageId = data['_fcm_message_id']?.toString().trim();
    if (messageId != null && messageId.isNotEmpty) {
      return 'message:$messageId';
    }
    return 'product:${data['product_id']}:${data['dispatch_id']}';
  }

  String _partnerNotificationKey(Map<String, dynamic> data) {
    final notificationId = data['notification_id']?.toString().trim();
    if (notificationId != null && notificationId.isNotEmpty) {
      return 'notification:$notificationId';
    }
    final messageId = data['_fcm_message_id']?.toString().trim();
    if (messageId != null && messageId.isNotEmpty) {
      return 'message:$messageId';
    }
    return 'partner:${data['partner_application_id']}:${data['status']}';
  }

  String _marketNotificationKey(Map<String, dynamic> data) {
    final notificationId = data['notification_id']?.toString().trim();
    if (notificationId != null && notificationId.isNotEmpty) {
      return 'notification:$notificationId';
    }
    final messageId = data['_fcm_message_id']?.toString().trim();
    if (messageId != null && messageId.isNotEmpty) {
      return 'message:$messageId';
    }
    return 'market:${data['market_id']}:${data['dispatch_id']}';
  }

  String _deliveryAreaNotificationKey(Map<String, dynamic> data) {
    final notificationId = data['notification_id']?.toString().trim();
    if (notificationId != null && notificationId.isNotEmpty) {
      return 'notification:$notificationId';
    }
    final messageId = data['_fcm_message_id']?.toString().trim();
    if (messageId != null && messageId.isNotEmpty) {
      return 'message:$messageId';
    }
    return 'delivery-area:${data['delivery_area_id']}:${data['area_name']}';
  }

  Future<void> _handleAccountRestored(
    Map<String, dynamic> data, {
    required bool opened,
    required bool queueForAppStart,
  }) async {
    _accountRestoredNotifier.markRestored();
    final key = _restoredNotificationKey(data);
    if (opened) {
      if (!_openedRestoredNotifications.add(key)) return;
    } else {
      if (!_displayedRestoredNotifications.add(key)) return;
      try {
        await _accountNotificationPresenter.showAccountRestored(data);
      } catch (error, stackTrace) {
        _debugPushError('account-restored display', error, stackTrace);
      }
    }
    final pushEvent = PushEvent(data, opened: opened);
    if (queueForAppStart) {
      _pendingInitialOpenedEvents.add(pushEvent);
      return;
    }
    _events.add(pushEvent);
  }

  String _restoredNotificationKey(Map<String, dynamic> data) {
    final notificationId = data['notification_id']?.toString().trim();
    if (notificationId != null && notificationId.isNotEmpty) {
      return 'notification:$notificationId';
    }
    final messageId = data['_fcm_message_id']?.toString().trim();
    if (messageId != null && messageId.isNotEmpty) {
      return 'message:$messageId';
    }
    return 'account_restored';
  }

  Future<void> _disableAccount() async {
    _accountRestoredNotifier.reset();
    await _accountInactiveNotifier.inactivateAfter(_tokenStore.clear);
  }

  Future<void> dispose() async {
    await _foregroundMessageSubscription?.cancel();
    await _openedMessageSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    await _events.close();
  }
}

void _debugPushError(String operation, Object error, StackTrace stackTrace) {
  if (!kDebugMode) return;
  debugPrint('Push notification $operation failed (${error.runtimeType}).');
  debugPrintStack(stackTrace: stackTrace);
}
