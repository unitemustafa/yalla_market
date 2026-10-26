import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/domain/data_page.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/cubit/paged_list_cubit.dart';
import 'package:yalla_market/features/store/data/repositories/store_remote_repository_impl.dart';
import 'package:yalla_market/features/store/domain/usecases/get_market_listing_usecase.dart';
import 'package:yalla_market/features/home/data/repositories/notification_remote_repository_impl.dart';
import 'package:yalla_market/features/store/data/repositories/order_remote_repository_impl.dart';
import '../helpers/fake_api_client.dart';
import '../helpers/pending_order_request_store_fake.dart';

void main() {
  test(
    '300 and 1000 items use bounded pages without duplicates or parallel requests',
    () async {
      for (final count in [300, 1000]) {
        final load = _Load(count);
        final cubit = PagedListCubit<int, String>(load, idOf: (i) => '$i');
        await cubit.configure('region-a');
        expect(cubit.state.items.length, 30);
        while (cubit.state.hasMore) {
          await Future.wait([cubit.loadMore(), cubit.loadMore()]);
        }
        expect(cubit.state.items, List.generate(count, (i) => i));
        expect(load.calls.length, (count / 30).ceil());
        await cubit.close();
      }
    },
  );
  test(
    'replaced region ignores a late page; failed extra page retries without losing cards',
    () async {
      final load = _Load(100);
      final cubit = PagedListCubit<int, String>(load, idOf: (i) => '$i');
      final old = Completer<ApiResult<DataPage<int>>>();
      load.handler = (q, p) => q == 'old'
          ? old.future
          : Future.value(
              ApiResult.success(DataPage(items: [9], count: 2, hasMore: true)),
            );
      final pending = cubit.configure('old');
      await cubit.configure('new');
      old.complete(
        const ApiResult.success(DataPage(items: [1], count: 1, hasMore: false)),
      );
      await pending;
      expect(cubit.state.items, [9]);
      load.handler = (_, _) async =>
          const ApiResult.failure(ServerFailure('offline'));
      await cubit.loadMore();
      expect(cubit.state.items, [9]);
      expect(cubit.state.moreError, 'offline');
      load.handler = (_, _) async => const ApiResult.success(
        DataPage(items: [10], count: 2, hasMore: false),
      );
      await cubit.loadMore();
      expect(cubit.state.items, [9, 10]);
      expect(load.calls.where((c) => c.$1 == 'new').map((c) => c.$2), [
        1,
        2,
        2,
      ]);
      await cubit.close();
    },
  );
  test(
    'market page requests server filters and rejects malformed/oversized data',
    () async {
      final client = FakeApiClient(
        (request) => {
          'results': [
            {'id': 1, 'name': 'Shop'},
          ],
          'count': 300,
          'next': 'next',
          'market_types': [],
          'total_count': 300,
        },
      );
      final repository = StoreRemoteRepositoryImpl(client);
      const query = (
        classificationId: '7',
        query: 'outside preview',
        typeId: '9',
        popular: false,
        latest: false,
        scope: 'city',
      );
      final result = await GetMarketListingUseCase(repository)(query);
      expect(result, isA<ApiSuccess>());
      expect(
        client.requests.single.queryParameters,
        containsPair('page_size', 30),
      );
      expect(
        client.requests.single.queryParameters,
        containsPair('market_type_id', '9'),
      );
      final malformed = StoreRemoteRepositoryImpl(
        FakeApiClient(
          (_) => {
            'results': List.generate(31, (i) => {'id': i}),
            'count': 31,
            'next': null,
          },
        ),
      );
      expect(await malformed.getMarketPage(query), isA<ApiFailure>());
    },
  );
  test(
    'notification and order page metadata includes totals outside the loaded page',
    () async {
      final notifications = NotificationRemoteRepositoryImpl(
        FakeApiClient((request) {
          expect(request.queryParameters, containsPair('page_size', 30));
          return {
            'results': [],
            'count': 300,
            'next': 'next',
            'unread_count': 200,
          };
        }),
      );
      final notificationPage = await notifications.getNotificationPage();
      expect((notificationPage as ApiSuccess).data.unreadCount, 200);
      final orders = OrderRemoteRepositoryImpl(
        FakeApiClient(
          (_) => {
            'results': [],
            'count': 300,
            'next': 'next',
            'delivered_count': 180,
          },
        ),
        requestStore: FakePendingOrderRequestStore(),
      );
      final orderPage = await orders.getOrderPage();
      expect((orderPage as ApiSuccess).data.deliveredCount, 180);
    },
  );
}

class _Load implements LoadPageUseCase<int, String> {
  _Load(this.count);
  final int count;
  final calls = <(String, int)>[];
  Future<ApiResult<DataPage<int>>> Function(String, int)? handler;
  @override
  Future<ApiResult<DataPage<int>>> call(String query, {int page = 1}) async {
    calls.add((query, page));
    if (handler != null) return handler!(query, page);
    final start = (page - 1) * 30;
    return ApiResult.success(
      DataPage(
        items: List.generate((count - start).clamp(0, 30), (i) => start + i),
        count: count,
        hasMore: start + 30 < count,
      ),
    );
  }
}
