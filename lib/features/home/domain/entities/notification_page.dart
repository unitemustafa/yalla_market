import '../../../../core/domain/data_page.dart';
import 'app_notification.dart';

class NotificationPage extends DataPage<AppNotification> {
  const NotificationPage({
    required super.items,
    required super.count,
    required super.hasMore,
    required this.unreadCount,
  });
  final int unreadCount;
}
