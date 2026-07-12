import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/notifications/push_notification_service.dart';
import 'package:yalla_market/core/session/account_inactive_notifier.dart';
import 'package:yalla_market/core/session/account_restored_notifier.dart';
import 'package:yalla_market/core/storage/token_store.dart';

import '../../helpers/fake_api_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  test('account_disabled data clears tokens before notifying auth', () async {
    final tokenStore = InMemoryTokenStore();
    await tokenStore.save(
      StoredAuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    final notifier = AccountInactiveNotifier();
    final service = PushNotificationService(
      FakeApiClient((_) => null),
      tokenStore,
      accountInactiveNotifier: notifier,
    );

    await service.handleDataForTesting({
      'event': 'account_disabled',
      'code': 'account_inactive',
    }, opened: false);

    expect(await tokenStore.read(), isNull);
    expect(notifier.isInactive, isTrue);
  });

  test('structured offer event is emitted without routing from text', () async {
    final service = PushNotificationService(
      FakeApiClient((_) => null),
      InMemoryTokenStore(),
    );
    final eventFuture = service.events.first;

    await service.handleDataForTesting({
      'event': 'offer_created',
      'action': 'open_offer',
      'offer_id': '15',
      'title': 'any title',
    }, opened: true);

    final event = await eventFuture;
    expect(event.opened, isTrue);
    expect(event.data['action'], 'open_offer');
    expect(event.data['offer_id'], '15');
  });

  test('account_restored foreground notification is shown once', () async {
    final presenter = FakeAccountNotificationPresenter();
    final restoredNotifier = AccountRestoredNotifier();
    final service = PushNotificationService(
      FakeApiClient((_) => null),
      InMemoryTokenStore(),
      accountRestoredNotifier: restoredNotifier,
      accountNotificationPresenter: presenter,
    );
    final data = <String, dynamic>{
      'event': 'account_restored',
      'notification_id': '42',
      'route': 'login',
    };

    await service.handleDataForTesting(data, opened: false);
    await service.handleDataForTesting(data, opened: false);

    expect(presenter.shown, hasLength(1));
    expect(presenter.shown.single['notification_id'], '42');
    expect(restoredNotifier.value, isTrue);
  });

  test('account_restored notification tap emits one login event', () async {
    final presenter = FakeAccountNotificationPresenter();
    final service = PushNotificationService(
      FakeApiClient((_) => null),
      InMemoryTokenStore(),
      accountRestoredNotifier: AccountRestoredNotifier(),
      accountNotificationPresenter: presenter,
    );
    await presenter.initialize(
      (data) => service.handleDataForTesting(data, opened: true),
    );
    final data = <String, dynamic>{
      'event': 'account_restored',
      'notification_id': '43',
      'route': 'login',
    };
    final openedEvent = service.events.firstWhere((event) => event.opened);

    await service.handleDataForTesting(data, opened: false);
    await presenter.tap(data);
    await presenter.tap(data);

    final event = await openedEvent;
    expect(event.data['route'], 'login');
    expect(event.data['notification_id'], '43');
  });

  test(
    'token refresh registers new token then unregisters old token',
    () async {
      SharedPreferences.setMockInitialValues({
        'push.last_registered_token': 'old-token',
      });
      final tokenStore = InMemoryTokenStore();
      await tokenStore.save(
        StoredAuthTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      final requests = <FakeApiRequest>[];
      final service = PushNotificationService(
        FakeApiClient((request) {
          requests.add(request);
          return null;
        }),
        tokenStore,
      );

      await service.handleTokenRefreshForTesting('new-token');

      expect(requests.map((request) => request.path), [
        '/notifications/devices/register/',
        '/notifications/devices/unregister/',
      ]);
      expect((requests.first.data as Map)['token'], 'new-token');
      expect((requests.last.data as Map)['token'], 'old-token');
    },
  );
}

class FakeAccountNotificationPresenter implements AccountNotificationPresenter {
  Future<void> Function(Map<String, dynamic> data)? _onTap;
  final List<Map<String, dynamic>> shown = [];

  @override
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  ) async {
    _onTap = onTap;
  }

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> showAccountRestored(Map<String, dynamic> data) async {
    shown.add(Map<String, dynamic>.from(data));
  }

  Future<void> tap(Map<String, dynamic> data) async {
    await _onTap!(Map<String, dynamic>.from(data));
  }
}
