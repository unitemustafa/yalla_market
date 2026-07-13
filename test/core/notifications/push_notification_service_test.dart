import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/notifications/push_notification_service.dart';
import 'package:yalla_market/core/session/account_inactive_notifier.dart';
import 'package:yalla_market/core/session/account_restored_notifier.dart';
import 'package:yalla_market/core/session/session_metadata.dart';
import 'package:yalla_market/core/storage/token_store.dart';

import '../../helpers/fake_api_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  test('account_disabled data clears tokens before notifying auth', () async {
    final tokenStore = InMemoryTokenStore();
    await tokenStore.save(_tokens());
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

  test('structured product event keeps direct product routing data', () async {
    final service = PushNotificationService(
      FakeApiClient((_) => null),
      InMemoryTokenStore(),
    );
    final eventFuture = service.events.first;

    await service.handleDataForTesting({
      'event': 'product_created',
      'action': 'open_product',
      'product_id': '44',
      'product_name': 'كشري مخصوص',
    }, opened: true);

    final event = await eventFuture;
    expect(event.opened, isTrue);
    expect(event.data['action'], 'open_product');
    expect(event.data['product_id'], '44');
  });

  test('delivery area foreground notification is shown once', () async {
    final presenter = FakeAccountNotificationPresenter();
    final service = PushNotificationService(
      FakeApiClient((_) => null),
      InMemoryTokenStore(),
      accountNotificationPresenter: presenter,
    );
    final data = <String, dynamic>{
      'event': 'delivery_area_created',
      'notification_id': '51',
      'delivery_area_id': '9',
      'title': 'وصلنا لمنطقتك',
      'message': 'تمت إضافة منطقة توصيل جديدة.',
    };
    final eventFuture = service.events.first;

    await service.handleDataForTesting(data, opened: false);
    await service.handleDataForTesting(data, opened: false);

    final event = await eventFuture;
    expect(event.opened, isFalse);
    expect(event.data['delivery_area_id'], '9');
    expect(presenter.deliveryAreasShown, hasLength(1));
  });

  test(
    'market foreground notification is shown once and keeps route data',
    () async {
      final presenter = FakeAccountNotificationPresenter();
      final service = PushNotificationService(
        FakeApiClient((_) => null),
        InMemoryTokenStore(),
        accountNotificationPresenter: presenter,
      );
      final data = <String, dynamic>{
        'event': 'market_created',
        'action': 'open_store',
        'notification_id': '71',
        'market_id': '12',
        'title': 'محل جديد',
        'message': 'المحل متاح دلوقتي.',
      };
      final eventFuture = service.events.first;

      await service.handleDataForTesting(data, opened: false);
      await service.handleDataForTesting(data, opened: false);

      final event = await eventFuture;
      expect(event.data['action'], 'open_store');
      expect(event.data['market_id'], '12');
      expect(presenter.marketsShown, hasLength(1));
    },
  );

  test(
    'product foreground notification is shown once with sound route data',
    () async {
      final presenter = FakeAccountNotificationPresenter();
      final service = PushNotificationService(
        FakeApiClient((_) => null),
        InMemoryTokenStore(),
        accountNotificationPresenter: presenter,
      );
      final data = <String, dynamic>{
        'event': 'product_created',
        'action': 'open_product',
        'notification_id': '81',
        'product_id': '44',
        'title': 'منتج جديد',
        'message': 'المنتج متاح دلوقتي.',
      };
      final eventFuture = service.events.first;

      await service.handleDataForTesting(data, opened: false);
      await service.handleDataForTesting(data, opened: false);

      final event = await eventFuture;
      expect(event.data['action'], 'open_product');
      expect(event.data['product_id'], '44');
      expect(presenter.productsShown, hasLength(1));
    },
  );

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
      await tokenStore.save(_tokens());
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

StoredAuthTokens _tokens() {
  final now = DateTime.now();
  final deadline = now.add(const Duration(hours: 8));
  return StoredAuthTokens(
    accessToken: 'access',
    refreshToken: 'refresh',
    accessExpiresAt: now.add(const Duration(minutes: 15)),
    refreshExpiresAt: deadline,
    sessionStartedAt: now,
    mode: AuthSessionMode.temporary,
    absoluteExpiresAt: deadline,
  );
}

class FakeAccountNotificationPresenter implements AccountNotificationPresenter {
  Future<void> Function(Map<String, dynamic> data)? _onTap;
  final List<Map<String, dynamic>> shown = [];
  final List<Map<String, dynamic>> deliveryAreasShown = [];
  final List<Map<String, dynamic>> marketsShown = [];
  final List<Map<String, dynamic>> productsShown = [];

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

  @override
  Future<void> showDeliveryAreaCreated(Map<String, dynamic> data) async {
    deliveryAreasShown.add(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> showMarketCreated(Map<String, dynamic> data) async {
    marketsShown.add(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> showProductCreated(Map<String, dynamic> data) async {
    productsShown.add(Map<String, dynamic>.from(data));
  }

  Future<void> tap(Map<String, dynamic> data) async {
    await _onTap!(Map<String, dynamic>.from(data));
  }
}
