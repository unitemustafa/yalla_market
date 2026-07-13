import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_cubit.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_state.dart';
import 'package:yalla_market/features/home/presentation/formatters/notification_time_formatter.dart';
import 'package:yalla_market/features/home/presentation/views/notifications_view.dart';
import 'package:yalla_market/core/routing/app_route_arguments.dart';
import 'package:yalla_market/core/routing/app_routes.dart';

import '../../helpers/notification_test_helpers.dart';

void main() {
  group('NotificationsView', () {
    testWidgets('shows initial loading without demo notifications', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(const NotificationState(isInitialLoading: true));
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      expect(find.text('Loading notifications...'), findsOneWidget);
      expect(find.text('Order confirmed'), findsNothing);
      expect(find.text('Popular categories updated'), findsNothing);
      expect(find.text('Shipment update'), findsNothing);
      expect(find.text('Account secured'), findsNothing);
    });

    testWidgets('shows initial error and retry calls load force refresh', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          const NotificationState(
            errorMessage: 'Server error.',
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);
      final callsAfterInitialPostFrame = cubit.loadCalls;

      expect(find.text('Notifications could not load'), findsOneWidget);
      expect(find.text('Server error.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(cubit.loadCalls, callsAfterInitialPostFrame + 1);
    });

    testWidgets('shows empty state without summary', (tester) async {
      final cubit = SpyNotificationCubit()
        ..seed(const NotificationState(hasLoaded: true));
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.textContaining('unread notifications'), findsNothing);
    });

    testWidgets('shows backend data and removes demo delete UI', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [
              testNotification(id: 1, isRead: false),
              testNotification(id: 2, isRead: true, orderId: 24),
            ],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      expect(find.text('Order rejected'), findsNWidgets(2));
      expect(find.text('Your order #12 was rejected.'), findsOneWidget);
      expect(find.byWidgetPredicate(isUnreadDot), findsOneWidget);
      expect(find.text('Delete selected'), findsNothing);
      expect(find.text('Selected notifications'), findsNothing);
      expect(find.byType(Dismissible), findsNWidgets(2));
      expect(find.text('Order confirmed'), findsNothing);
      expect(find.text('Popular categories updated'), findsNothing);
      expect(find.text('Shipment update'), findsNothing);
      expect(find.text('Account secured'), findsNothing);
    });

    testWidgets('mark all read calls cubit and loading state is disabled', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(isRead: false)],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      await tester.tap(find.byTooltip('Mark all as read'));
      await tester.pump();

      expect(cubit.markAllCalls, 1);
      expect(find.text('0 unread notifications'), findsOneWidget);

      cubit.seed(
        NotificationState(
          notifications: [testNotification(isRead: false)],
          unreadCount: 1,
          isMarkingAllRead: true,
          hasLoaded: true,
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Mark all as read'));
      await tester.pump();

      expect(cubit.markAllCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      cubit.seed(
        NotificationState(
          notifications: [testNotification(isRead: true)],
          unreadCount: 0,
          hasLoaded: true,
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Mark all as read'));
      await tester.pump();

      expect(cubit.markAllCalls, 1);
    });

    testWidgets('swiping a notification deletes it from the list', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(id: 41, isRead: false)],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      await tester.drag(
        find.byKey(const ValueKey('notification-41')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(cubit.deleteCalls, 1);
      expect(find.byKey(const ValueKey('notification-41')), findsNothing);
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.text('Notification deleted'), findsOneWidget);
    });

    testWidgets('visible delete button removes a notification', (tester) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(id: 42, isRead: false)],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);
      await tester.tap(find.byKey(const ValueKey('notification-delete-42')));
      await tester.pumpAndSettle();

      expect(cubit.deleteCalls, 1);
      expect(find.byKey(const ValueKey('notification-42')), findsNothing);
      expect(find.text('Notification deleted'), findsOneWidget);
    });

    testWidgets('opening unread notification marks it read once', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(id: 7, isRead: false)],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      await tester.tap(find.text('Your order #12 was rejected.'));
      await tester.pumpAndSettle();

      expect(find.text('Notification details'), findsOneWidget);
      expect(cubit.markReadCalls, 1);
      expect(cubit.lastMarkedReadId, 7);
      expect(find.byWidgetPredicate(isUnreadDot), findsNothing);
      expect(find.text('0 unread notifications'), findsOneWidget);
    });

    testWidgets('opening read notification does not mark it read again', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(id: 8, isRead: true)],
            unreadCount: 0,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      await tester.tap(find.text('Your order #12 was rejected.'));
      await tester.pumpAndSettle();

      expect(find.text('Notification details'), findsOneWidget);
      expect(cubit.markReadCalls, 0);
    });

    testWidgets('mark read failure keeps unread state and shows snackbar', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..markReadSucceeds = false
        ..seed(
          NotificationState(
            notifications: [testNotification(id: 9, isRead: false)],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      await tester.tap(find.text('Your order #12 was rejected.'));
      await tester.pump();
      await tester.pump();

      expect(cubit.markReadCalls, 1);
      expect(find.byWidgetPredicate(isUnreadDot), findsOneWidget);
      expect(find.text('Could not mark notification as read.'), findsOneWidget);
    });

    testWidgets('pull to refresh calls cubit and keeps old data visible', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(isRead: false)],
            unreadCount: 1,
            isRefreshing: true,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      expect(find.text('Your order #12 was rejected.'), findsOneWidget);

      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      expect(refreshIndicator.color, isNull);
      expect(refreshIndicator.displacement, 40);
      await refreshIndicator.onRefresh();
      await tester.pump();

      expect(cubit.refreshCalls, 1);
      expect(find.text('Your order #12 was rejected.'), findsOneWidget);
      expect(find.text('Notifications updated'), findsOneWidget);
    });

    testWidgets('dragging down the notification list triggers refresh', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(isRead: false)],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      await tester.fling(find.byType(ListView), const Offset(0, 500), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(cubit.refreshCalls, 1);
    });

    testWidgets('unknown type renders raw title and message', (tester) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [
              testNotification(
                type: 'future_type',
                title: 'Backend title',
                message: 'Backend message',
                orderId: null,
              ),
            ],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpNotificationsView(tester, cubit);

      expect(find.text('Backend title'), findsOneWidget);
      expect(find.text('Backend message'), findsOneWidget);
    });

    testWidgets('product notification opens the product details route', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [
              testNotification(
                type: 'product_created',
                title: '🛒 منتج جديد وصل يلا ماركت!',
                message: 'دوس وشوف تفاصيل المنتج.',
                orderId: null,
                productId: 44,
                data: const {
                  'action': 'open_product',
                  'product_id': 44,
                  'product_name': 'كشري مخصوص',
                  'market_name': 'محل المدينة',
                  'price_text': 'EGP 80',
                  'discount': '10.00',
                },
              ),
            ],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);
      RouteSettings? capturedSettings;

      await _pumpNotificationsView(
        tester,
        cubit,
        onGenerateRoute: (settings) {
          capturedSettings = settings;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Product details')),
          );
        },
      );

      await tester.tap(find.text('دوس وشوف تفاصيل المنتج.'));
      await tester.pumpAndSettle();

      expect(capturedSettings?.name, AppRoutes.productDetail);
      final args = capturedSettings?.arguments as ProductDetailRouteArgs;
      expect(args.productId, '44');
      expect(args.title, 'كشري مخصوص');
      expect(args.brand, 'محل المدينة');
    });

    testWidgets('market notification opens the announced store route', (
      tester,
    ) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [
              testNotification(
                type: 'market_created',
                title: 'محل جديد',
                message: 'افتح المحل وشوف منتجاته.',
                orderId: null,
                data: const {
                  'action': 'open_store',
                  'market_id': 18,
                  'market_name': 'محل الأسماك',
                  'classification_id': 7,
                  'image': '/media/markets/fish.webp',
                },
              ),
            ],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);
      RouteSettings? capturedSettings;

      await _pumpNotificationsView(
        tester,
        cubit,
        onGenerateRoute: (settings) {
          capturedSettings = settings;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Store products')),
          );
        },
      );

      await tester.tap(find.text('افتح المحل وشوف منتجاته.'));
      await tester.pumpAndSettle();

      expect(capturedSettings?.name, AppRoutes.brandProducts);
      final args = capturedSettings?.arguments as BrandProductsRouteArgs;
      expect(args.marketId, '18');
      expect(args.brand, 'محل الأسماك');
      expect(args.classificationId, '7');
    });

    testWidgets('relative time formatter is deterministic with injected now', (
      tester,
    ) async {
      late String justNow;
      late String yesterday;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final now = DateTime(2026, 7, 5, 12);
              justNow = NotificationTimeFormatter.format(
                context,
                now.subtract(const Duration(seconds: 10)),
                now: now,
              );
              yesterday = NotificationTimeFormatter.format(
                context,
                now.subtract(const Duration(days: 1, minutes: 1)),
                now: now,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(justNow, 'Just now');
      expect(yesterday, 'Yesterday');
    });
  });
}

Future<void> _pumpNotificationsView(
  WidgetTester tester,
  NotificationCubit cubit, {
  RouteFactory? onGenerateRoute,
}) async {
  await tester.pumpWidget(
    BlocProvider<NotificationCubit>.value(
      value: cubit,
      child: MaterialApp(
        home: const NotificationsView(),
        onGenerateRoute: onGenerateRoute,
      ),
    ),
  );
  await tester.pump();
}
