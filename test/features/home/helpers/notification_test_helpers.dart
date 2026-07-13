import 'package:flutter/material.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/home/domain/entities/app_notification.dart';
import 'package:yalla_market/features/home/domain/repositories/notification_repository.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_cubit.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_state.dart';

AppNotification testNotification({
  int id = 1,
  String type = 'order_rejected',
  String title = 'Order rejected',
  String message = 'Your order #12 was rejected.',
  int? orderId = 12,
  int? productId,
  Map<String, dynamic> data = const {},
  bool isRead = false,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    audience: 'client',
    type: type,
    title: title,
    message: message,
    orderId: orderId,
    productId: productId,
    data: data,
    isRead: isRead,
    createdAt: createdAt ?? DateTime(2026, 7, 5, 12),
  );
}

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({List<AppNotification> notifications = const []})
    : notifications = List.of(notifications);

  final List<AppNotification> notifications;
  Failure? listFailure;
  Failure? markReadFailure;
  Failure? markAllFailure;
  Failure? deleteFailure;
  int listCalls = 0;
  int unreadCountCalls = 0;
  int markReadCalls = 0;
  int markAllCalls = 0;
  int deleteCalls = 0;

  @override
  Future<ApiResult<List<AppNotification>>> getNotifications({
    bool? unread,
    String? type,
  }) async {
    listCalls++;
    if (listFailure case final failure?) return ApiResult.failure(failure);
    return ApiResult.success(List.unmodifiable(notifications));
  }

  @override
  Future<ApiResult<int>> getUnreadCount() async {
    unreadCountCalls++;
    return ApiResult.success(
      notifications.where((item) => !item.isRead).length,
    );
  }

  @override
  Future<ApiResult<AppNotification>> markAsRead(int notificationId) async {
    markReadCalls++;
    if (markReadFailure case final failure?) return ApiResult.failure(failure);
    final index = notifications.indexWhere((item) => item.id == notificationId);
    final updated = notifications[index].copyWith(isRead: true);
    notifications[index] = updated;
    return ApiResult.success(updated);
  }

  @override
  Future<ApiResult<bool>> deleteNotification(int notificationId) async {
    deleteCalls++;
    if (deleteFailure case final failure?) return ApiResult.failure(failure);
    notifications.removeWhere((item) => item.id == notificationId);
    return const ApiResult.success(true);
  }

  @override
  Future<ApiResult<int>> markAllAsRead() async {
    markAllCalls++;
    if (markAllFailure case final failure?) return ApiResult.failure(failure);
    final unreadCount = notifications.where((item) => !item.isRead).length;
    for (var index = 0; index < notifications.length; index++) {
      notifications[index] = notifications[index].copyWith(isRead: true);
    }
    return ApiResult.success(unreadCount);
  }
}

class SpyNotificationCubit extends NotificationCubit {
  SpyNotificationCubit({FakeNotificationRepository? repository})
    : this._(repository ?? FakeNotificationRepository());

  SpyNotificationCubit._(this.repository) : super(repository);

  final FakeNotificationRepository repository;
  int loadCalls = 0;
  int refreshCalls = 0;
  int refreshUnreadCountCalls = 0;
  int markReadCalls = 0;
  int markAllCalls = 0;
  int deleteCalls = 0;
  int clearCalls = 0;
  int? lastMarkedReadId;
  bool markReadSucceeds = true;
  bool markAllSucceeds = true;
  bool deleteSucceeds = true;

  void seed(NotificationState state) => emit(state);

  @override
  Future<void> loadNotifications({bool forceRefresh = false}) async {
    loadCalls++;
  }

  @override
  Future<void> refreshNotifications() async {
    refreshCalls++;
  }

  @override
  Future<void> refreshUnreadCount() async {
    refreshUnreadCountCalls++;
  }

  @override
  Future<bool> markNotificationRead(int id) async {
    markReadCalls++;
    lastMarkedReadId = id;
    if (!markReadSucceeds) {
      emit(
        state.copyWith(errorMessage: 'Could not mark notification as read.'),
      );
      return false;
    }

    emit(
      state.copyWith(
        notifications: List.unmodifiable(
          state.notifications.map((item) {
            return item.id == id ? item.copyWith(isRead: true) : item;
          }),
        ),
        unreadCount: state.unreadCount <= 0 ? 0 : state.unreadCount - 1,
        clearError: true,
      ),
    );
    return true;
  }

  @override
  Future<bool> markAllRead() async {
    markAllCalls++;
    if (!markAllSucceeds) {
      emit(state.copyWith(errorMessage: 'Could not mark notifications.'));
      return false;
    }

    emit(
      state.copyWith(
        notifications: List.unmodifiable(
          state.notifications.map((item) => item.copyWith(isRead: true)),
        ),
        unreadCount: 0,
        isMarkingAllRead: false,
        clearError: true,
      ),
    );
    return true;
  }

  @override
  Future<bool> deleteNotification(int id) async {
    deleteCalls++;
    if (!deleteSucceeds) {
      emit(state.copyWith(errorMessage: 'Could not delete notification.'));
      return false;
    }
    return true;
  }

  @override
  void clear() {
    clearCalls++;
    super.clear();
  }
}

bool isUnreadDot(Widget widget) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;
  if (decoration is! BoxDecoration) return false;
  return decoration.shape == BoxShape.circle && decoration.color != null;
}
