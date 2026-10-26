import '../../../../core/network/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';
import '../entities/notification_page.dart';

class NotificationUseCases {
  const NotificationUseCases(this._repository);

  final NotificationRepository _repository;

  bool get supportsPaging => _repository is PagedNotificationRepository;
  Future<ApiResult<NotificationPage>> page({int page = 1}) async {
    if (page < 1) {
      return const ApiResult.failure(
        ValidationFailure('Invalid notification page.'),
      );
    }
    final repository = _repository;
    if (repository is PagedNotificationRepository) {
      return (repository as PagedNotificationRepository).getNotificationPage(
        page: page,
      );
    }
    final result = await getNotifications();
    return result.when(
      success: (items) => ApiResult.success(
        NotificationPage(
          items: items,
          count: items.length,
          hasMore: false,
          unreadCount: items.where((item) => !item.isRead).length,
        ),
      ),
      failure: ApiResult.failure,
    );
  }

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
