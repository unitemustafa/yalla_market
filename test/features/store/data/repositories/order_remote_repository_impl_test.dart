import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/data/repositories/order_remote_repository_impl.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('OrderRemoteRepositoryImpl', () {
    test('creates an order with the Django order contract', () async {
      late FakeApiRequest capturedRequest;
      final apiClient = FakeApiClient((request) {
        capturedRequest = request;
        return {
          'id': 1,
          'order_number': 'YM-20260627-000001',
          'status': 'pending',
          'created_at': DateTime(2026).toIso8601String(),
          'delivery_address': _address.toJson(),
          'payment_method': 'cash_on_delivery',
          'items': [
            {
              'id': 7,
              'quantity': 1,
              'unit_price': '10.00',
              'variant': {
                'id': 10,
                'price': '10.00',
                'product': {'id': 2, 'name': 'Fresh product'},
              },
            },
          ],
          'subtotal_price': '10.00',
          'delivery_price': '0.00',
          'discount': '0.00',
          'total_price': '10.00',
        };
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.createOrder(
        shippingAddress: _address,
        items: const [_item],
        paymentMethod: 'visa',
        deliveryType: 'manual_quote',
        customDeliveryArea: 'Unlisted area',
      );

      result.when(
        success: (order) => expect(order.paymentMethod, 'cash_on_delivery'),
        failure: (failure) => fail(failure.message),
      );
      expect(
        capturedRequest.data,
        containsPair('payment_method', 'cash_on_delivery'),
      );
      expect(capturedRequest.data, containsPair('delivery_address_id', 12));
      expect(
        capturedRequest.data,
        containsPair('delivery_type', 'manual_quote'),
      );
      expect(
        capturedRequest.data,
        containsPair('custom_delivery_area', 'Unlisted area'),
      );
      expect((capturedRequest.data as Map<String, dynamic>)['items'], [
        {'variant_id': 10, 'quantity': 1},
      ]);
    });
  });
}

const _address = ShippingAddressData(
  id: '12',
  fullName: 'Mustafa Ali',
  phone: '+201000000000',
  line1: 'Street 1',
  city: 'Cairo',
  state: 'Cairo',
  country: 'Egypt',
  postalCode: '11511',
);

const _item = OrderItemData(
  id: 'item-1',
  variantId: '10',
  image: 'image.png',
  brand: 'Yalla',
  title: 'Fresh product',
  unitPrice: 10,
  quantity: 1,
);
