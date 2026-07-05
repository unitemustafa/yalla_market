import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/home/domain/entities/app_notification.dart';
import 'package:yalla_market/features/home/domain/repositories/notification_repository.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_cubit.dart';

void main() {
  group('NotificationCubit', () {
    test('initial load sorts newest first and computes unread count', () async {
      final repository = _FakeNotificationRepository(
        notifications: [
          _notification(id: 1, createdAt: DateTime(2026), isRead: false),
          _notification(id: 2, createdAt: DateTime(2027), isRead: true),
        ],
      );
      final cubit = NotificationCubit(repository);

      await cubit.loadNotifications();

      expect(cubit.state.hasLoaded, isTrue);
      expect(cubit.state.notifications.first.id, 2);
      expect(cubit.state.unreadCount, 1);
      await cubit.close();
    });

    test('initial failure exposes an error without data', () async {
      final cubit = NotificationCubit(
        _FakeNotificationRepository(
          failure: const ServerFailure('Server error.'),
        ),
      );

      await cubit.loadNotifications();

      expect(cubit.state.notifications, isEmpty);
      expect(cubit.state.errorMessage, 'Server error.');
      await cubit.close();
    });

    test('refresh failure keeps existing notifications', () async {
      final repository = _FakeNotificationRepository(
        notifications: [_notification(id: 1, isRead: false)],
      );
      final cubit = NotificationCubit(repository);
      await cubit.loadNotifications();
      repository.failure = const ServerFailure('Refresh failed.');

      await cubit.refreshNotifications();

      expect(cubit.state.notifications, hasLength(1));
      expect(cubit.state.errorMessage, 'Refresh failed.');
      await cubit.close();
    });

    test('mark unread notification success updates item and badge', () async {
      final cubit = NotificationCubit(
        _FakeNotificationRepository(
          notifications: [_notification(id: 1, isRead: false)],
        ),
      );
      await cubit.loadNotifications();

      final success = await cubit.markNotificationRead(1);

      expect(success, isTrue);
      expect(cubit.state.notifications.single.isRead, isTrue);
      expect(cubit.state.unreadCount, 0);
      await cubit.close();
    });

    test('mark read failure leaves item unread', () async {
      final repository = _FakeNotificationRepository(
        notifications: [_notification(id: 1, isRead: false)],
      );
      final cubit = NotificationCubit(repository);
      await cubit.loadNotifications();
      repository.markReadFailure = const ServerFailure('Patch failed.');

      final success = await cubit.markNotificationRead(1);

      expect(success, isFalse);
      expect(cubit.state.notifications.single.isRead, isFalse);
      expect(cubit.state.unreadCount, 1);
      await cubit.close();
    });

    test('already read notification does not send PATCH', () async {
      final repository = _FakeNotificationRepository(
        notifications: [_notification(id: 1, isRead: true)],
      );
      final cubit = NotificationCubit(repository);
      await cubit.loadNotifications();

      final success = await cubit.markNotificationRead(1);

      expect(success, isTrue);
      expect(repository.markReadCalls, 0);
      await cubit.close();
    });

    test('mark all success marks every item read', () async {
      final cubit = NotificationCubit(
        _FakeNotificationRepository(
          notifications: [
            _notification(id: 1, isRead: false),
            _notification(id: 2, isRead: false),
          ],
        ),
      );
      await cubit.loadNotifications();

      final success = await cubit.markAllRead();

      expect(success, isTrue);
      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.notifications.every((item) => item.isRead), isTrue);
      await cubit.close();
    });

    test('clear drops state and ignores stale responses', () async {
      final completer = Completer<ApiResult<List<AppNotification>>>();
      final repository = _FakeNotificationRepository(loadCompleter: completer);
      final cubit = NotificationCubit(repository);
      final load = cubit.loadNotifications();

      cubit.clear();
      completer.complete(
        ApiResult.success([_notification(id: 1, isRead: false)]),
      );
      await load;

      expect(cubit.state.notifications, isEmpty);
      expect(cubit.state.unreadCount, 0);
      await cubit.close();
    });
  });
}

AppNotification _notification({
  required int id,
  bool isRead = false,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    audience: 'client',
    type: 'order_rejected',
    title: 'Order rejected',
    message: 'Your order #12 was rejected.',
    orderId: 12,
    isRead: isRead,
    createdAt: createdAt ?? DateTime(2026, 7, 5),
  );
}

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({
    List<AppNotification> notifications = const [],
    this.failure,
    this.loadCompleter,
  }) : notifications = List.of(notifications);

  final List<AppNotification> notifications;
  final Completer<ApiResult<List<AppNotification>>>? loadCompleter;
  Failure? failure;
  Failure? markReadFailure;
  Failure? markAllFailure;
  int markReadCalls = 0;

  @override
  Future<ApiResult<List<AppNotification>>> getNotifications({
    bool? unread,
    String? type,
  }) async {
    if (loadCompleter case final completer?) return completer.future;
    if (failure case final error?) return ApiResult.failure(error);
    return ApiResult.success(List.unmodifiable(notifications));
  }

  @override
  Future<ApiResult<int>> getUnreadCount() async {
    return ApiResult.success(
      notifications.where((item) => !item.isRead).length,
    );
  }

  @override
  Future<ApiResult<AppNotification>> markAsRead(int notificationId) async {
    markReadCalls++;
    if (markReadFailure case final error?) return ApiResult.failure(error);
    final notification = notifications.firstWhere(
      (item) => item.id == notificationId,
    );
    return ApiResult.success(notification.copyWith(isRead: true));
  }

  @override
  Future<ApiResult<int>> markAllAsRead() async {
    if (markAllFailure case final error?) return ApiResult.failure(error);
    return ApiResult.success(
      notifications.where((item) => !item.isRead).length,
    );
  }
}
