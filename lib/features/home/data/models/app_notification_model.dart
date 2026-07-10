import '../../domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.audience,
    required super.type,
    required super.title,
    required super.message,
    required super.createdAt,
    super.orderId,
    super.offerId,
    super.data,
    super.isRead,
    super.isBlocking,
    super.isResolved,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: _intFromJson(json['id']) ?? 0,
      audience: _stringFromJson(json['audience']),
      type: _stringFromJson(json['type']),
      title: _stringFromJson(json['title']),
      message: _stringFromJson(json['message']),
      orderId: _intFromJson(json['order_id']),
      offerId: _intFromJson(json['offer_id']),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      isRead: _boolFromJson(json['is_read']),
      isBlocking: _boolFromJson(json['is_blocking']),
      isResolved: _boolFromJson(json['is_resolved']),
      createdAt: _dateFromJson(json['created_at']),
    );
  }
}

String _stringFromJson(Object? value) => value is String ? value : '';

bool _boolFromJson(Object? value) => value is bool ? value : false;

int? _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime _dateFromJson(Object? value) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
