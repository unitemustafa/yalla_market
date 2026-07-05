import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/session/session_expired_notifier.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_session.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_state.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_cubit.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_state.dart';

import '../../../../helpers/auth_widget_fakes.dart';
import '../../../../helpers/domain_fixtures.dart';
import '../../helpers/notification_test_helpers.dart';

void main() {
  group('notification session lifecycle', () {
    testWidgets('authenticated refreshes unread count only', (tester) async {
      final authCubit = _authCubit();
      final notificationCubit = SpyNotificationCubit();
      addTearDown(authCubit.close);
      addTearDown(notificationCubit.close);

      await _pumpLifecycleHarness(tester, authCubit, notificationCubit);

      authCubit.hydrate(sampleSession);
      await tester.pump();

      expect(notificationCubit.refreshUnreadCountCalls, 1);
      expect(notificationCubit.loadCalls, 0);
    });

    testWidgets('auth initial clears notification state', (tester) async {
      final authCubit = _authCubit();
      final notificationCubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(isRead: false)],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(authCubit.close);
      addTearDown(notificationCubit.close);

      await _pumpLifecycleHarness(tester, authCubit, notificationCubit);

      authCubit.hydrate(sampleSession);
      await tester.pump();
      await authCubit.logout();
      await tester.pump();

      expect(notificationCubit.clearCalls, 1);
      expect(notificationCubit.state.notifications, isEmpty);
      expect(notificationCubit.state.unreadCount, 0);
    });

    testWidgets('session expired clears notification state', (tester) async {
      final authCubit = _authCubit();
      final notificationCubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(isRead: false)],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(authCubit.close);
      addTearDown(notificationCubit.close);

      await _pumpLifecycleHarness(tester, authCubit, notificationCubit);

      authCubit.hydrate(sampleSession);
      await tester.pump();
      authCubit.markSessionExpired();
      await tester.pump();

      expect(notificationCubit.clearCalls, 1);
      expect(notificationCubit.state.notifications, isEmpty);
      expect(notificationCubit.state.unreadCount, 0);
    });

    testWidgets('new authenticated user does not see previous user data', (
      tester,
    ) async {
      final authCubit = _authCubit();
      final notificationCubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(id: 1, isRead: false)],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(authCubit.close);
      addTearDown(notificationCubit.close);

      await _pumpLifecycleHarness(tester, authCubit, notificationCubit);

      authCubit.hydrate(sampleSession);
      await tester.pump();
      await authCubit.logout();
      await tester.pump();

      authCubit.hydrate(
        AuthSession(
          user: sampleUser.copyWith(id: 'user_2', email: 'next@example.com'),
        ),
      );
      await tester.pump();

      expect(notificationCubit.refreshUnreadCountCalls, 2);
      expect(notificationCubit.state.notifications, isEmpty);
      expect(notificationCubit.state.unreadCount, 0);
    });
  });
}

AuthCubit _authCubit() {
  return AuthCubit(
    authUseCases(FakeAuthRepository()),
    sessionExpiredNotifier: SessionExpiredNotifier(),
  );
}

Future<void> _pumpLifecycleHarness(
  WidgetTester tester,
  AuthCubit authCubit,
  NotificationCubit notificationCubit,
) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<NotificationCubit>.value(value: notificationCubit),
      ],
      child: MaterialApp(
        home: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.read<NotificationCubit>().refreshUnreadCount();
            } else if (state is AuthInitial || state is AuthSessionExpired) {
              context.read<NotificationCubit>().clear();
            }
          },
          child: const SizedBox.shrink(),
        ),
      ),
    ),
  );
}
