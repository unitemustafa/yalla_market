import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/features/home/domain/entities/notification_page.dart';
import 'package:yalla_market/features/home/domain/repositories/notification_repository.dart';
import 'package:yalla_market/features/home/domain/usecases/notification_usecases.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/order_history_page.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_my_orders_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_state.dart';
import '../features/home/helpers/notification_test_helpers.dart';
import '../helpers/test_order_repository.dart';

void main() {
  test(
    'refresh replaces an in-flight order page without blocking later paging',
    () async {
      final repository = _Orders();
      final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));
      addTearDown(cubit.close);
      await cubit.loadOrders();
      final late = Completer<ApiResult<OrderHistoryPage>>();
      repository.pending = late;
      final more = cubit.loadMore();
      repository.pending = null;
      await cubit.loadOrders(force: true);
      late.complete(const ApiResult.failure(ServerFailure('obsolete')));
      await more;
      await cubit.loadMore();
      expect(repository.pages, [1, 2, 1, 2]);
      expect((cubit.state as OrderHistoryReady).orders.length, 2);
    },
  );

  test('a failed notification refresh cancels obsolete page loading', () async {
    final repository = _Notifications();
    final cubit = NotificationCubit(NotificationUseCases(repository));
    addTearDown(cubit.close);
    await cubit.loadNotifications();
    final late = Completer<ApiResult<NotificationPage>>();
    repository.pending = late;
    final more = cubit.loadMore();
    repository.fail = true;
    await cubit.refreshNotifications();
    late.complete(const ApiResult.failure(ServerFailure('obsolete')));
    await more;
    expect(cubit.state.loadingMore, isFalse);
    repository.fail = false;
    repository.pending = null;
    await cubit.loadMore();
    expect(cubit.state.notifications.length, 60);
  });

  test(
    'different global notification actions are serialized rather than coalesced',
    () async {
      final repository = _Notifications();
      final cubit = NotificationCubit(NotificationUseCases(repository));
      addTearDown(cubit.close);
      await cubit.loadNotifications();
      final read = cubit.markAllRead();
      final remove = cubit.deleteAllNotifications();
      expect(await read, isTrue);
      expect(await remove, isTrue);
      expect(repository.notifications, isEmpty);
      expect(repository.clearReadCalls, 1);
    },
  );

  test(
    'notification badge counts all 300 records and mark all applies to unloaded pages',
    () async {
      final repository = _Notifications();
      final cubit = NotificationCubit(NotificationUseCases(repository));
      addTearDown(cubit.close);
      await cubit.loadNotifications();
      expect(cubit.state.notifications.length, 30);
      expect(cubit.state.unreadCount, 300);
      await Future.wait([cubit.loadMore(), cubit.loadMore()]);
      expect(cubit.state.notifications.length, 60);
      expect(repository.pages, [1, 2]);
      expect(await cubit.markAllRead(), isTrue);
      await cubit.loadMore();
      expect(cubit.state.notifications.length, 90);
      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.notifications.every((n) => n.isRead), isTrue);
    },
  );
  test(
    'late notification page cannot undo mark all or restore its unread badge',
    () async {
      final repository = _Notifications();
      final cubit = NotificationCubit(NotificationUseCases(repository));
      addTearDown(cubit.close);
      await cubit.loadNotifications();
      final late = Completer<ApiResult<NotificationPage>>();
      repository.pending = late;
      final loading = cubit.loadMore();
      await cubit.markAllRead();
      late.complete(
        ApiResult.success(
          NotificationPage(
            items: [testNotification(id: 31)],
            count: 300,
            hasMore: true,
            unreadCount: 300,
          ),
        ),
      );
      await loading;
      expect(cubit.state.notifications.length, 30);
      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.loadingMore, isFalse);
    },
  );
  test(
    'order paging keeps global summary, retries failed page and sends date range to server',
    () async {
      final repository = _Orders();
      final cubit = OrderHistoryCubit(GetMyOrdersUseCase(repository));
      addTearDown(cubit.close);
      await cubit.loadOrders();
      expect((cubit.state as OrderHistoryReady).totalCount, 300);
      expect((cubit.state as OrderHistoryReady).deliveredCount, 200);
      repository.fail = true;
      await cubit.loadMore();
      expect((cubit.state as OrderHistoryReady).orders.length, 1);
      expect((cubit.state as OrderHistoryReady).moreError, 'offline');
      repository.fail = false;
      await cubit.loadMore();
      expect((cubit.state as OrderHistoryReady).orders.map((o) => o.id), [
        '1',
        '2',
      ]);
      expect(repository.pages, [1, 2, 2]);
      final start = DateTime(2030, 1, 1);
      final end = DateTime(2030, 1, 2);
      await cubit.selectRange(start, end);
      expect(repository.range, (start, end));
      expect((cubit.state as OrderHistoryReady).totalCount, 20);
      expect((cubit.state as OrderHistoryReady).orders.length, 1);
    },
  );
}

class _Notifications extends FakeNotificationRepository
    implements PagedNotificationRepository {
  _Notifications()
    : super(
        notifications: List.generate(300, (i) => testNotification(id: i + 1)),
      );
  final pages = <int>[];
  bool fail = false;
  Completer<ApiResult<NotificationPage>>? pending;
  @override
  Future<ApiResult<NotificationPage>> getNotificationPage({
    int page = 1,
  }) async {
    pages.add(page);
    if (fail) return const ApiResult.failure(ServerFailure('offline'));
    if (page > 1 && pending != null) return pending!.future;
    return ApiResult.success(
      NotificationPage(
        items: List.unmodifiable(notifications.skip((page - 1) * 30).take(30)),
        count: notifications.length,
        hasMore: page * 30 < notifications.length,
        unreadCount: notifications.where((n) => !n.isRead).length,
      ),
    );
  }
}

class _Orders extends TestOrderRepository
    implements PagedOrderHistoryRepository {
  final pages = <int>[];
  (DateTime?, DateTime?)? range;
  bool fail = false;
  Completer<ApiResult<OrderHistoryPage>>? pending;
  @override
  Future<ApiResult<OrderHistoryPage>> getOrderPage({
    int page = 1,
    DateTime? start,
    DateTime? end,
  }) async {
    pages.add(page);
    range = (start, end);
    if (page > 1 && pending != null) return pending!.future;
    if (fail) return const ApiResult.failure(ServerFailure('offline'));
    return ApiResult.success(
      OrderHistoryPage(
        items: [
          OrderData.fromJson({
            'id': page,
            'created_at': '2030-01-01T12:00:00Z',
            'status': 'pending',
          }),
        ],
        count: start == null ? 300 : 20,
        hasMore: true,
        deliveredCount: start == null ? 200 : 5,
      ),
    );
  }
}
