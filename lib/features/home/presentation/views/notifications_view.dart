import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../formatters/notification_time_formatter.dart';
import '../mappers/notification_presentation_mapper.dart';

part 'notification_toolbar_widgets.dart';
part 'notification_card_widgets.dart';
part 'notification_detail_widgets.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationCubit>().loadNotifications(forceRefresh: true);
    });
  }

  Future<void> _refresh() {
    return context.read<NotificationCubit>().refreshNotifications();
  }

  Future<void> _markAllRead() async {
    final success = await context.read<NotificationCubit>().markAllRead();
    if (!mounted || success) return;
    CustomSnackBar.showError(
      context: context,
      title: 'Could not mark notifications as read.',
    );
  }

  Future<void> _openNotification(AppNotification notification) async {
    final wasUnread = !notification.isRead;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return _NotificationDetailSheet(
          notification: notification,
          isDark: isDark,
        );
      },
    );

    if (!wasUnread) return;
    final success = await context
        .read<NotificationCubit>()
        .markNotificationRead(notification.id);
    if (!mounted || success) return;
    CustomSnackBar.showError(
      context: context,
      title: 'Could not mark notification as read.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: BlocConsumer<NotificationCubit, NotificationState>(
          listenWhen: (previous, current) {
            return previous.isRefreshing &&
                !current.isRefreshing &&
                previous.notifications.isNotEmpty &&
                current.errorMessage != null;
          },
          listener: (context, state) {
            CustomSnackBar.showError(
              context: context,
              title: 'Could not refresh notifications.',
            );
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final maxContentWidth = constraints.maxWidth >= 760
                    ? 680.0
                    : constraints.maxWidth;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        children: [
                          PageTopBar(
                            title: 'Notifications',
                            subtitle: 'Orders, deals and account updates',
                            actions: [
                              _MarkAllReadButton(
                                isDark: isDark,
                                isLoading: state.isMarkingAllRead,
                                enabled: state.unreadCount > 0,
                                onPressed: _markAllRead,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (state.isInitialLoading)
                            const SizedBox(
                              height: 420,
                              child: AppLoadingState(
                                message: 'Loading notifications...',
                              ),
                            )
                          else if (state.notifications.isEmpty &&
                              state.errorMessage != null)
                            SizedBox(
                              height: 420,
                              child: AppErrorState(
                                title: 'Notifications could not load',
                                message: state.errorMessage!,
                                onRetry: () => context
                                    .read<NotificationCubit>()
                                    .loadNotifications(forceRefresh: true),
                              ),
                            )
                          else if (state.notifications.isEmpty)
                            const SizedBox(
                              height: 420,
                              child: _EmptyNotificationsView(),
                            )
                          else ...[
                            _NotificationSummary(
                              isDark: isDark,
                              unreadCount: state.unreadCount,
                            ),
                            const SizedBox(height: 22),
                            for (final notification in state.notifications)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _NotificationCard(
                                  notification: notification,
                                  isDark: isDark,
                                  onTap: () => _openNotification(notification),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
