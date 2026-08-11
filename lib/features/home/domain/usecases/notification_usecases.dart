import '../../../../core/network/api_result.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class NotificationUseCases {
  const NotificationUseCases(this._repository);

  final NotificationRepository _repository;

  Future<ApiResult<List<AppNotification>>> getNotifications({
    bool? unread,
    String? type,
  }) {
    return _repository.getNotifications(unread: unread, type: type);
  }

  Future<ApiResult<AppNotification>> markAsRead(int notificationId) {
    return _repository.markAsRead(notificationId);
  }

  Future<ApiResult<bool>> deleteNotification(int notificationId) {
    return _repository.deleteNotification(notificationId);
  }

  Future<ApiResult<int>> clearReadNotifications() {
    return _repository.clearReadNotifications();
  }

  Future<ApiResult<int>> markAllAsRead() {
    return _repository.markAllAsRead();
  }

  Future<ApiResult<int>> getUnreadCount() {
    return _repository.getUnreadCount();
  }
}
