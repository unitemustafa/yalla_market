import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/coalesced_operation.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit(this._useCases) : super(const NotificationState());

  final NotificationUseCases _useCases;
  final _loads = CoalescedOperation();
  int _generation = 0;
  int _page = 1;
  int _contentRevision = 0;
  final Set<int> _removedIds = {};
  Future<bool>? _mutation;
  String? _mutationKind;
  int _sessionGeneration = 0;

  Future<bool> _runMutation(String kind, Future<bool> Function() action) async {
    final running = _mutation;
    if (running != null) {
      if (_mutationKind == kind) return running;
      final session = _sessionGeneration;
      await running;
      if (isClosed || session != _sessionGeneration) return false;
      return _runMutation(kind, action);
    }
    final generation = _generation;
    final operation = () async {
      if (_loads.isRunning) await _loads.run(() async {});
      if (isClosed || generation != _generation) return false;
      return action();
    }();
    _mutation = operation;
    _mutationKind = kind;
    try {
      return await operation;
    } finally {
      if (identical(_mutation, operation)) {
        _mutation = null;
        _mutationKind = null;
      }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.loadingMore ||
        _loads.isRunning ||
        state.isDeletingAll ||
        state.isMarkingAllRead) {
      return;
    }
    final generation = _generation;
    final revision = _contentRevision;
    emit(state.copyWith(loadingMore: true, clearMoreError: true));
    final result = await _useCases.page(page: _page + 1);
    if (isClosed || generation != _generation) {
      return;
    }
    result.when(
      success: (data) {
        _page++;
        final merged = {for (final item in state.notifications) item.id: item};
        for (final item in data.items) {
          if (!_removedIds.contains(item.id)) {
            merged.putIfAbsent(item.id, () => item);
          }
        }
        emit(
          state.copyWith(
            notifications: List.unmodifiable(merged.values),
            loadingMore: false,
            hasMore: data.hasMore,
            unreadCount: revision == _contentRevision
                ? data.unreadCount
                : state.unreadCount,
          ),
        );
      },
      failure: (failure) =>
          emit(state.copyWith(loadingMore: false, moreError: failure.message)),
    );
  }

  Future<void> loadNotifications({bool forceRefresh = false}) async {
    final mutation = _mutation;
    if (mutation != null) await mutation;
    if (isClosed) return;
    await _loads.run(() => _loadNotifications(forceRefresh: forceRefresh));
  }

  Future<void> _loadNotifications({bool forceRefresh = false}) async {
    if (state.hasLoaded && !forceRefresh) return;

    final generation = ++_generation;
    final isInitial = !state.hasLoaded && state.notifications.isEmpty;
    emit(
      state.copyWith(
        isInitialLoading: isInitial,
        isRefreshing: !isInitial,
        loadingMore: false,
        clearMoreError: true,
        clearError: true,
        markingReadIds: const {},
      ),
    );

    final result = await _useCases.page();
    if (generation != _generation || isClosed) return;

    result.when(
      success: (page) {
        _page = 1;
        _removedIds.clear();
        final sorted = List<AppNotification>.of(page.items)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(
          state.copyWith(
            notifications: List.unmodifiable(sorted),
            unreadCount: page.unreadCount,
            hasMore: page.hasMore,
            loadingMore: false,
            clearMoreError: true,
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
    final revision = _contentRevision;
    final result = await _useCases.getUnreadCount();
    if (generation != _generation || revision != _contentRevision || isClosed) {
      return;
    }

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

    final result = await _useCases.markAsRead(id);
    if (generation != _generation || isClosed) return false;

    return result.when(
      success: (_) {
        _contentRevision++;
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
    final result = await _useCases.deleteNotification(id);
    if (generation != _generation || isClosed) return false;

    return result.when(
      success: (_) => true,
      failure: (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
    );
  }

  Future<bool> deleteAllNotifications() =>
      _runMutation('delete', _deleteAllNotifications);

  Future<bool> _deleteAllNotifications() async {
    if (state.notifications.isEmpty) return true;
    if (state.isDeletingAll) return false;

    final generation = ++_generation;
    _contentRevision++;
    emit(
      state.copyWith(
        loadingMore: false,
        markingReadIds: const {},
        isDeletingAll: true,
        clearError: true,
      ),
    );

    final markResult = await _useCases.markAllAsRead();
    if (generation != _generation || isClosed) return false;

    var markedAll = false;
    String? failureMessage;
    markResult.when(
      success: (_) => markedAll = true,
      failure: (failure) => failureMessage = failure.message,
    );
    if (!markedAll) {
      emit(state.copyWith(isDeletingAll: false, errorMessage: failureMessage));
      return false;
    }

    final clearResult = await _useCases.clearReadNotifications();
    if (generation != _generation || isClosed) return false;

    return clearResult.when(
      success: (_) {
        final protectedNotifications = state.notifications
            .where((item) => item.isBlocking && !item.isResolved)
            .map((item) => item.copyWith(isRead: true))
            .toList(growable: false);
        emit(
          state.copyWith(
            notifications: List.unmodifiable(protectedNotifications),
            unreadCount: 0,
            isDeletingAll: false,
            hasMore: false,
            clearError: true,
          ),
        );
        if (_useCases.supportsPaging) {
          _page = 1;
          loadNotifications(forceRefresh: true);
        }
        return true;
      },
      failure: (failure) {
        emit(
          state.copyWith(
            notifications: List.unmodifiable(
              state.notifications.map((item) => item.copyWith(isRead: true)),
            ),
            unreadCount: 0,
            isDeletingAll: false,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
    );
  }

  void removeNotification(int id) {
    final index = state.notifications.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final notification = state.notifications[index];
    _removedIds.add(id);
    _contentRevision++;

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

  Future<bool> markAllRead() => _runMutation('read', _markAllRead);

  Future<bool> _markAllRead() async {
    if (state.unreadCount == 0 || state.isMarkingAllRead) return true;

    final generation = ++_generation;
    _contentRevision++;
    emit(
      state.copyWith(
        loadingMore: false,
        markingReadIds: const {},
        isMarkingAllRead: true,
        clearError: true,
      ),
    );
    final result = await _useCases.markAllAsRead();
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
    _sessionGeneration++;
    _mutation = null;
    _mutationKind = null;
    _loads.reset();
    _generation++;
    _page = 1;
    _removedIds.clear();
    _contentRevision++;
    emit(const NotificationState());
  }

  int _nonNegative(int value) => value < 0 ? 0 : value;
}
