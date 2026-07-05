import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/home/data/models/app_notification_model.dart';

void main() {
  group('AppNotificationModel', () {
    test('parses backend notification payload safely', () {
      final notification = AppNotificationModel.fromJson({
        'id': 1,
        'audience': 'client',
        'type': 'order_rejected',
        'title': 'Order rejected',
        'message': 'Your order #12 was rejected.',
        'order_id': null,
        'is_read': false,
        'created_at': '2026-07-05T10:30:00Z',
      });

      expect(notification.id, 1);
      expect(notification.orderId, isNull);
      expect(notification.isRead, isFalse);
      expect(notification.isBlocking, isFalse);
      expect(notification.isResolved, isFalse);
      expect(notification.createdAt.toUtc().year, 2026);
    });

    test(
      'keeps unknown types and missing optional fields without crashing',
      () {
        final notification = AppNotificationModel.fromJson({
          'id': 2,
          'type': 'future_type',
          'created_at': 'bad-date',
        });

        expect(notification.id, 2);
        expect(notification.type, 'future_type');
        expect(notification.audience, isEmpty);
        expect(notification.title, isEmpty);
        expect(notification.message, isEmpty);
        expect(notification.createdAt.millisecondsSinceEpoch, 0);
      },
    );
  });
}
