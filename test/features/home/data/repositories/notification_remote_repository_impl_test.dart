import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/home/data/repositories/notification_remote_repository_impl.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('NotificationRemoteRepositoryImpl', () {
    test('GET list parses direct list response', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/notifications/');
        expect(request.queryParameters, isNull);
        return [_payload(id: 1, isRead: false)];
      });
      final repository = NotificationRemoteRepositoryImpl(apiClient);

      final result = await repository.getNotifications();

      result.when(
        success: (items) {
          expect(items, hasLength(1));
          expect(items.single.id, 1);
          expect(items.single.isRead, isFalse);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('GET list sends query parameters only when requested', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.queryParameters, {
          'unread': 'true',
          'type': 'order_rejected',
        });
        return [];
      });
      final repository = NotificationRemoteRepositoryImpl(apiClient);

      await repository.getNotifications(unread: true, type: 'order_rejected');
    });

    test('PATCH read returns updated notification', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'PATCH');
        expect(request.path, '/notifications/7/read/');
        return _payload(id: 7, isRead: true);
      });
      final repository = NotificationRemoteRepositoryImpl(apiClient);

      final result = await repository.markAsRead(7);

      result.when(
        success: (item) => expect(item.isRead, isTrue),
        failure: (failure) => fail(failure.message),
      );
    });

    test('POST mark all returns marked_read count', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'POST');
        expect(request.path, '/notifications/mark-all-read/');
        return {'marked_read': 3};
      });
      final repository = NotificationRemoteRepositoryImpl(apiClient);

      final result = await repository.markAllAsRead();

      result.when(
        success: (count) => expect(count, 3),
        failure: (failure) => fail(failure.message),
      );
    });

    test('DELETE clear read returns deleted count', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'DELETE');
        expect(request.path, '/notifications/clear-read/');
        return {'deleted_count': 4};
      });
      final repository = NotificationRemoteRepositoryImpl(apiClient);

      final result = await repository.clearReadNotifications();

      result.when(
        success: (count) => expect(count, 4),
        failure: (failure) => fail(failure.message),
      );
    });

    test('GET unread count never returns a negative value', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/notifications/unread-count/');
        return {'unread_count': -4};
      });
      final repository = NotificationRemoteRepositoryImpl(apiClient);

      final result = await repository.getUnreadCount();

      result.when(
        success: (count) => expect(count, 0),
        failure: (failure) => fail(failure.message),
      );
    });
  });
}

Map<String, dynamic> _payload({required int id, required bool isRead}) {
  return {
    'id': id,
    'audience': 'client',
    'type': 'order_rejected',
    'title': 'Order rejected',
    'message': 'Your order #12 was rejected.',
    'order_id': 12,
    'is_read': isRead,
    'is_blocking': false,
    'is_resolved': false,
    'created_at': '2026-07-05T10:30:00Z',
  };
}
