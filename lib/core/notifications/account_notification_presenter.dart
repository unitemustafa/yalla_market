import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const accountUpdatesChannelId = 'account_updates';
const accountUpdatesChannelName = 'تحديثات الحساب';
const orderUpdatesChannelId = 'order_updates';
const orderUpdatesChannelName = 'تحديثات الطلبات';
const deliveryUpdatesChannelId = 'delivery_updates';
const deliveryUpdatesChannelName = 'تحديثات مناطق التوصيل';
const storeUpdatesChannelId = 'store_updates';
const storeUpdatesChannelName = 'المحلات الجديدة';
const productUpdatesChannelId = 'product_updates';
const productUpdatesChannelName = 'المنتجات الجديدة';
const offerUpdatesChannelId = 'offer_updates';
const offerUpdatesChannelName = 'العروض الجديدة';
const partnerUpdatesChannelId = 'partner_updates';
const partnerUpdatesChannelName = 'تحديثات الشراكة';
const accountRestoredTitle = 'تم استعادة حسابك';
const accountRestoredMessage = 'تم استعادة حسابك بواسطة فريق دعم يلا ماركت.';

abstract interface class AccountNotificationPresenter {
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  );

  Future<void> requestPermission();

  Future<void> showAccountRestored(Map<String, dynamic> data);

  Future<void> showDeliveryAreaCreated(Map<String, dynamic> data);

  Future<void> showMarketCreated(Map<String, dynamic> data);

  Future<void> showProductCreated(Map<String, dynamic> data);

  Future<void> showOfferCreated(Map<String, dynamic> data);

  Future<void> showPartnerApplicationApproved(Map<String, dynamic> data);
}

class FlutterAccountNotificationPresenter
    implements AccountNotificationPresenter {
  FlutterAccountNotificationPresenter({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const AndroidNotificationChannel _accountChannel =
      AndroidNotificationChannel(
        accountUpdatesChannelId,
        accountUpdatesChannelName,
        description: 'إشعارات تعطيل واستعادة حساب العميل',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _deliveryChannel =
      AndroidNotificationChannel(
        deliveryUpdatesChannelId,
        deliveryUpdatesChannelName,
        description: 'إشعارات إضافة مناطق توصيل جديدة',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
        orderUpdatesChannelId,
        orderUpdatesChannelName,
        description: 'إشعارات حالة طلبات العميل والتوصيل',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _storeChannel =
      AndroidNotificationChannel(
        storeUpdatesChannelId,
        storeUpdatesChannelName,
        description: 'إشعارات المحلات الجديدة المتاحة في منطقتك',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _productChannel =
      AndroidNotificationChannel(
        productUpdatesChannelId,
        productUpdatesChannelName,
        description: 'إشعارات المنتجات الجديدة المتاحة في منطقتك',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _offerChannel =
      AndroidNotificationChannel(
        offerUpdatesChannelId,
        offerUpdatesChannelName,
        description: 'إشعارات العروض الجديدة المتاحة في منطقتك',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _partnerChannel =
      AndroidNotificationChannel(
        partnerUpdatesChannelId,
        partnerUpdatesChannelName,
        description: 'إشعارات الموافقة على طلبات الشراكة',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  @override
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  ) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            unawaited(onTap(Map<String, dynamic>.from(decoded)));
          }
        } catch (error, stackTrace) {
          _debugNotificationError('local notification tap', error, stackTrace);
        }
      },
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_accountChannel);
    await androidPlugin?.createNotificationChannel(_orderChannel);
    await androidPlugin?.createNotificationChannel(_deliveryChannel);
    await androidPlugin?.createNotificationChannel(_storeChannel);
    await androidPlugin?.createNotificationChannel(_productChannel);
    await androidPlugin?.createNotificationChannel(_offerChannel);
    await androidPlugin?.createNotificationChannel(_partnerChannel);
  }

  @override
  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> showAccountRestored(Map<String, dynamic> data) async {
    final notificationId = int.tryParse(
      data['notification_id']?.toString() ?? '',
    );
    await _plugin.show(
      id: notificationId ?? accountRestoredTitle.hashCode & 0x7fffffff,
      title: accountRestoredTitle,
      body: accountRestoredMessage,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          accountUpdatesChannelId,
          accountUpdatesChannelName,
          channelDescription: 'إشعارات تعطيل واستعادة حساب العميل',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  @override
  Future<void> showDeliveryAreaCreated(Map<String, dynamic> data) async {
    final notificationId = int.tryParse(
      data['notification_id']?.toString() ?? '',
    );
    final title = data['title']?.toString().trim() ?? '';
    final message = data['message']?.toString().trim() ?? '';
    if (title.isEmpty && message.isEmpty) return;

    await _plugin.show(
      id:
          notificationId ??
          Object.hash(title, message, data['delivery_area_id']) & 0x7fffffff,
      title: title.isEmpty ? 'منطقة توصيل جديدة' : title,
      body: message.isEmpty ? null : message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          deliveryUpdatesChannelId,
          deliveryUpdatesChannelName,
          channelDescription: 'إشعارات إضافة مناطق توصيل جديدة',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  @override
  Future<void> showMarketCreated(Map<String, dynamic> data) async {
    final notificationId = int.tryParse(
      data['notification_id']?.toString() ?? '',
    );
    final title = data['title']?.toString().trim() ?? '';
    final message = data['message']?.toString().trim() ?? '';
    if (title.isEmpty && message.isEmpty) return;

    await _plugin.show(
      id:
          notificationId ??
          Object.hash(title, message, data['market_id']) & 0x7fffffff,
      title: title.isEmpty ? 'محل جديد متاح' : title,
      body: message.isEmpty ? null : message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          storeUpdatesChannelId,
          storeUpdatesChannelName,
          channelDescription: 'إشعارات المحلات الجديدة المتاحة في منطقتك',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  @override
  Future<void> showProductCreated(Map<String, dynamic> data) async {
    final notificationId = int.tryParse(
      data['notification_id']?.toString() ?? '',
    );
    final title = data['title']?.toString().trim() ?? '';
    final message = data['message']?.toString().trim() ?? '';
    if (title.isEmpty && message.isEmpty) return;

    await _plugin.show(
      id:
          notificationId ??
          Object.hash(title, message, data['product_id']) & 0x7fffffff,
      title: title.isEmpty ? 'منتج جديد متاح' : title,
      body: message.isEmpty ? null : message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          productUpdatesChannelId,
          productUpdatesChannelName,
          channelDescription: 'إشعارات المنتجات الجديدة المتاحة في منطقتك',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  @override
  Future<void> showOfferCreated(Map<String, dynamic> data) async {
    final notificationId = int.tryParse(
      data['notification_id']?.toString() ?? '',
    );
    final title = data['title']?.toString().trim() ?? '';
    final message = data['message']?.toString().trim() ?? '';
    if (title.isEmpty && message.isEmpty) return;

    await _plugin.show(
      id:
          notificationId ??
          Object.hash(title, message, data['offer_id']) & 0x7fffffff,
      title: title.isEmpty ? 'عرض جديد متاح' : title,
      body: message.isEmpty ? null : message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          offerUpdatesChannelId,
          offerUpdatesChannelName,
          channelDescription: 'إشعارات العروض الجديدة المتاحة في منطقتك',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  @override
  Future<void> showPartnerApplicationApproved(Map<String, dynamic> data) async {
    final notificationId = int.tryParse(
      data['notification_id']?.toString() ?? '',
    );
    final title = data['title']?.toString().trim() ?? '';
    final message = data['message']?.toString().trim() ?? '';
    if (title.isEmpty && message.isEmpty) return;

    await _plugin.show(
      id:
          notificationId ??
          Object.hash(title, message, data['partner_application_id']) &
              0x7fffffff,
      title: title.isEmpty ? 'تم قبول طلب الشراكة' : title,
      body: message.isEmpty ? null : message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          partnerUpdatesChannelId,
          partnerUpdatesChannelName,
          channelDescription: 'إشعارات الموافقة على طلبات الشراكة',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }
}

void _debugNotificationError(
  String operation,
  Object error,
  StackTrace stackTrace,
) {
  debugPrint('Push notification $operation failed: $error');
  debugPrintStack(stackTrace: stackTrace);
}
