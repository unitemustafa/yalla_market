import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/notifications/push_notification_service.dart';
import 'package:yalla_market/core/session/account_inactive_notifier.dart';
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
