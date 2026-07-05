import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/app_notification_model.dart';

abstract final class NotificationApiPaths {
  static const notifications = '/notifications/';
  static const markAllRead = '/notifications/mark-all-read/';
  static const unreadCount = '/notifications/unread-count/';

  static String read(int id) => '/notifications/$id/read/';
}

class NotificationRemoteRepositoryImpl implements NotificationRepository {
  NotificationRemoteRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<List<AppNotification>>> getNotifications({
    bool? unread,
    String? type,
  }) {
    return _guard(() async {
      final query = <String, dynamic>{};
      if (unread != null) query['unread'] = unread ? 'true' : 'false';
      if (type != null && type.trim().isNotEmpty) query['type'] = type.trim();

      final payload = await _apiClient.get<Object?>(
        NotificationApiPaths.notifications,
        queryParameters: query.isEmpty ? null : query,
      );
      if (payload is! List) return const <AppNotification>[];

      return payload
          .whereType<Map<String, dynamic>>()
          .map(AppNotificationModel.fromJson)
          .toList(growable: false);
    });
  }

  @override
  Future<ApiResult<AppNotification>> markAsRead(int notificationId) {
    return _guard(() async {
      final payload = await _apiClient.patch<Object?>(
        NotificationApiPaths.read(notificationId),
      );
      if (payload is Map<String, dynamic>) {
        return AppNotificationModel.fromJson(payload);
      }
      throw const FormatException('Invalid notification payload.');
    });
  }

  @override
  Future<ApiResult<int>> markAllAsRead() {
    return _guard(() async {
      final payload = await _apiClient.post<Object?>(
        NotificationApiPaths.markAllRead,
      );
      if (payload is Map<String, dynamic>) {
        final markedRead = payload['marked_read'];
        if (markedRead is int) return markedRead;
        if (markedRead is num) return markedRead.toInt();
      }
      return 0;
    });
  }

  @override
  Future<ApiResult<int>> getUnreadCount() {
    return _guard(() async {
      final payload = await _apiClient.get<Object?>(
        NotificationApiPaths.unreadCount,
      );
      if (payload is Map<String, dynamic>) {
        final unreadCount = payload['unread_count'];
        if (unreadCount is int) return unreadCount < 0 ? 0 : unreadCount;
        if (unreadCount is num) {
          final count = unreadCount.toInt();
          return count < 0 ? 0 : count;
        }
      }
      return 0;
    });
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not update notifications.'),
      );
    }
  }
}
