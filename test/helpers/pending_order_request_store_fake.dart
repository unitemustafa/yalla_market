import 'package:yalla_market/features/store/data/datasources/pending_order_request_store.dart';

class FakePendingOrderRequestStore implements PendingOrderRequestStore {
  final Map<String, String> requests = {};
  int _nextKey = 0;

  @override
  Future<PendingOrderRequest> prepare(String fingerprint) async {
    return PendingOrderRequest(
      userId: 'test-user',
      fingerprint: fingerprint,
      key: requests.putIfAbsent(
        fingerprint,
        () => (++_nextKey).toRadixString(16).padLeft(32, '0'),
      ),
    );
  }

  @override
  Future<void> complete(PendingOrderRequest request) async {
    if (requests[request.fingerprint] == request.key) {
      requests.remove(request.fingerprint);
    }
  }
}
