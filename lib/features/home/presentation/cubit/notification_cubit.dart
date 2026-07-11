import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit(this._repository) : super(const NotificationState());

  final NotificationRepository _repository;
  int _generation = 0;

  Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (state.isInitialLoading || state.isRefreshing) return;
    if (state.hasLoaded && !forceRefresh) return;

    final generation = _generation;
    final isInitial = !state.hasLoaded && state.notifications.isEmpty;
    emit(
      state.copyWith(
        isInitialLoading: isInitial,
        isRefreshing: !isInitial,
        clearError: true,
      ),
    );

    final result = await _repository.getNotifications();
    if (generation != _generation || isClosed) return;

    result.when(
      success: (notifications) {
        final sorted = List<AppNotification>.of(notifications)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(
          state.copyWith(
            notifications: List.unmodifiable(sorted),
            unreadCount: sorted.where((item) => !item.isRead).length,
            isInitialLoading: false,
            isRefreshing: false,
            hasLoaded: true,
            clearError: true,
          ),
        );
      },
      failure: (failure) {
        emit(
          state.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            errorMessage: failure.message,
            hasLoaded: state.hasLoaded || state.notifications.isNotEmpty,
          ),
        );
      },
    );
  }

  Future<void> refreshNotifications() {
    return loadNotifications(forceRefresh: true);
  }

  Future<void> refreshUnreadCount() async {
    final generation = _generation;
    final result = await _repository.getUnreadCount();
    if (generation != _generation || isClosed) return;

    result.when(
      success: (count) => emit(
        state.copyWith(unreadCount: count < 0 ? 0 : count, clearError: true),
      ),
      failure: (_) {},
    );
  }

  Future<bool> markNotificationRead(int id) async {
    final index = state.notifications.indexWhere((item) => item.id == id);
    if (index == -1) return false;
    if (state.notifications[index].isRead) return true;
    if (state.markingReadIds.contains(id)) return false;

    final nextMarking = Set<int>.of(state.markingReadIds)..add(id);
    final generation = _generation;
    emit(state.copyWith(markingReadIds: nextMarking, clearError: true));

    final result = await _repository.markAsRead(id);
    if (generation != _generation || isClosed) return false;

    return result.when(
      success: (_) {
        final nextNotifications = List<AppNotification>.of(state.notifications);
        final currentIndex = nextNotifications.indexWhere(
          (item) => item.id == id,
        );
        if (currentIndex != -1) {
          nextNotifications[currentIndex] = nextNotifications[currentIndex]
              .copyWith(isRead: true);
        }
        final nextIds = Set<int>.of(state.markingReadIds)..remove(id);
        emit(
          state.copyWith(
            notifications: List.unmodifiable(nextNotifications),
            unreadCount: _nonNegative(state.unreadCount - 1),
            markingReadIds: nextIds,
            clearError: true,
          ),
        );
        return true;
      },
      failure: (failure) {
        final nextIds = Set<int>.of(state.markingReadIds)..remove(id);
        emit(
          state.copyWith(
            markingReadIds: nextIds,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
    );
  }

  Future<bool> deleteNotification(int id) async {
    if (!state.notifications.any((item) => item.id == id)) return false;

    final generation = _generation;
    final result = await _repository.deleteNotification(id);
    if (generation != _generation || isClosed) return false;

    return result.when(
      success: (_) => true,
      failure: (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
    );
  }

  void removeNotification(int id) {
    final index = state.notifications.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final notification = state.notifications[index];

    emit(
      state.copyWith(
        notifications: List.unmodifiable(
          state.notifications.where((item) => item.id != id),
        ),
        unreadCount: notification.isRead
            ? state.unreadCount
            : _nonNegative(state.unreadCount - 1),
        clearError: true,
      ),
    );
  }

  Future<bool> markAllRead() async {
    if (state.unreadCount == 0 || state.isMarkingAllRead) return true;

    final generation = _generation;
    emit(state.copyWith(isMarkingAllRead: true, clearError: true));
    final result = await _repository.markAllAsRead();
    if (generation != _generation || isClosed) return false;

    return result.when(
      success: (_) {
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
      },
      failure: (failure) {
        emit(
          state.copyWith(
            isMarkingAllRead: false,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
    );
  }

  void clear() {
    _generation++;
    emit(const NotificationState());
  }

  int _nonNegative(int value) => value < 0 ? 0 : value;
}
