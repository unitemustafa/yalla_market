import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/data/repositories/order_unavailable_repository_impl.dart';

import '../../../../helpers/domain_fixtures.dart';

void main() {
  group('OrderUnavailableRepositoryImpl', () {
    test('rejects order creation without reporting fake success', () async {
      final repository = OrderUnavailableRepositoryImpl();

      final result = await repository.createOrder(
        shippingAddress: sampleShippingAddress,
        items: const [sampleOrderItem],
      );

      result.when(
        success: (_) => fail('Order creation must stay disabled.'),
        failure: (failure) =>
            expect(failure.message, orderCreationUnavailableMessage),
      );
    });

    test('rejects order history without making a request', () async {
      final repository = OrderUnavailableRepositoryImpl();

      final result = await repository.getMyOrders();

      result.when(
        success: (_) => fail('Order history must stay disabled.'),
        failure: (failure) => expect(failure.message, isNotEmpty),
      );
    });
  });
}
