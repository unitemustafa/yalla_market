import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/notifications/push_notification_service.dart';
import 'package:yalla_market/yalla_market_app.dart';

void main() {
  test('foreground delivery area event presents the root banner', () async {
    Map<String, dynamic>? shownData;
    final event = PushEvent({
      'event': 'delivery_area_created',
      'notification_id': '51',
      'title': 'وصلنا لمنطقتك',
      'message': 'تمت إضافة منطقة توصيل جديدة.',
    }, opened: false);

    final presented = await presentDeliveryAreaCreatedFeedback(
      pushEvent: event,
      showBanner: (data) async => shownData = data,
    );

    expect(presented, isTrue);
    expect(shownData?['notification_id'], '51');
  });

  test(
    'opened delivery area event does not duplicate the root banner',
    () async {
      var showCalls = 0;
      final event = PushEvent({
        'event': 'delivery_area_created',
        'notification_id': '51',
      }, opened: true);

      final presented = await presentDeliveryAreaCreatedFeedback(
        pushEvent: event,
        showBanner: (_) async => showCalls++,
      );

      expect(presented, isFalse);
      expect(showCalls, 0);
    },
  );
}
