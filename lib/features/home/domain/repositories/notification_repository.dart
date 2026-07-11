import '../../../../core/network/api_result.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<ApiResult<List<AppNotification>>> getNotifications({
    bool? unread,
    String? type,
  });

  Future<ApiResult<AppNotification>> markAsRead(int notificationId);

  Future<ApiResult<bool>> deleteNotification(int notificationId);

  Future<ApiResult<int>> markAllAsRead();

  Future<ApiResult<int>> getUnreadCount();
}
