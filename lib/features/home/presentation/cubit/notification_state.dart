import '../../domain/entities/app_notification.dart';

class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isMarkingAllRead = false,
    this.isDeletingAll = false,
    this.markingReadIds = const <int>{},
    this.errorMessage,
    this.hasLoaded = false,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isMarkingAllRead;
  final bool isDeletingAll;
  final Set<int> markingReadIds;
  final String? errorMessage;
  final bool hasLoaded;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isMarkingAllRead,
    bool? isDeletingAll,
    Set<int>? markingReadIds,
    String? errorMessage,
    bool clearError = false,
    bool? hasLoaded,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
      isDeletingAll: isDeletingAll ?? this.isDeletingAll,
      markingReadIds: markingReadIds ?? this.markingReadIds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}
