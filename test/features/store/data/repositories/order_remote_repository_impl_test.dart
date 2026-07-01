import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
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

    test('loads orders from paginated results payload', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/orders/my/');
        return {
          'count': 1,
          'next': null,
          'previous': null,
          'results': [
            {
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
            },
          ],
        };
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.getMyOrders();

      result.when(
        success: (orders) {
          expect(orders, hasLength(1));
          expect(orders.single.orderNumber, 'YM-20260627-000001');
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('parses list response from GET orders endpoint', () async {
      final createdAt = DateTime.utc(2026, 7, 1, 17, 48, 30);
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/orders/my/');
        return [
          {
            'id': 9,
            'user_id': 15,
            'delivery_address_id': 2,
            'assigned_representative_id': null,
            'market_id': 5,
            'payment_method': 'cash_on_delivery',
            'discount': '20.00',
            'description': 'Leave at door',
            'status': 'pending',
            'delivery_price': '250.00',
            'subtotal_price': '890.00',
            'total_price': '1120.00',
            'image': null,
            'assigned_at': null,
            'delivered_at': null,
            'delivery_note': '',
            'delivery_proof': null,
            'items': [
              {
                'id': 21,
                'variant_id': 2,
                'quantity': 2,
                'unit_price': '320.00',
              },
            ],
            'offers': [
              {
                'id': 10,
                'offer_id': 4,
                'discount_amount': '20.00',
                'created_at': '2026-07-01T17:48:30.473909Z',
              },
            ],
            'created_at': createdAt.toIso8601String(),
            'updated_at': '2026-07-01T17:48:30.456948Z',
          },
        ];
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.getMyOrders();

      result.when(
        success: (orders) {
          expect(orders, hasLength(1));
          final order = orders.single;
          expect(order.id, '9');
          expect(order.orderNumber, '9');
          expect(order.status, OrderStatus.pending);
          expect(order.placedAt, createdAt);
          expect(order.subtotal, 890);
          expect(order.shippingFee, 250);
          expect(order.discountTotal, 20);
          expect(order.total, 1120);
          expect(order.items, hasLength(1));
          expect(order.items.single.id, '21');
          expect(order.items.single.variantId, '2');
          expect(order.items.single.quantity, 2);
          expect(order.items.single.unitPrice, 320);
          expect(order.items.single.title, isEmpty);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('sends POST orders preview with product items', () async {
      late FakeApiRequest capturedRequest;
      final apiClient = FakeApiClient((request) {
        capturedRequest = request;
        return _previewPayload;
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.previewOrder(
        cartItems: const [
          CartItemData(
            id: 'cart-1',
            productId: 'product-1',
            variantId: '23',
            image: 'image.png',
            brand: 'Yalla',
            title: 'Fresh product',
            price: 700,
            quantity: 2,
          ),
        ],
      );

      result.when(success: (_) {}, failure: (failure) => fail(failure.message));
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.path, '/orders/preview/');
      expect((capturedRequest.data as Map<String, dynamic>)['items'], [
        {'variant_id': 23, 'quantity': 2},
      ]);
      expect((capturedRequest.data as Map<String, dynamic>)['offers'], isEmpty);
    });

    test('parses preview summary', () async {
      final apiClient = FakeApiClient((request) => _previewPayload);
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.previewOrder(
        cartItems: const [
          CartItemData(
            id: 'cart-1',
            variantId: '23',
            image: 'image.png',
            brand: 'Yalla',
            title: 'Fresh product',
            price: 700,
            quantity: 2,
          ),
        ],
      );

      result.when(
        success: (preview) {
          expect(preview.summary.subtotal, 2975);
          expect(preview.summary.discountTotal, 168);
          expect(preview.summary.deliveryTotal, 250);
          expect(preview.summary.grandTotal, 3057);
          expect(preview.hasUnavailableDelivery, isFalse);
        },
        failure: (failure) => fail(failure.message),
      );
    });
  });
}

const _previewPayload = {
  'addresses': [
    {'id': 1, 'name': 'Home'},
  ],
  'selected_address': {'id': 1, 'name': 'Home'},
  'market_groups': [
    {
      'market': {'id': 5, 'name': 'Market'},
      'delivery_area': {'id': 2, 'name': 'Cairo'},
      'delivery_available': true,
      'selected_products': [],
      'selected_offers': [],
      'pricing': {
        'products_subtotal': '1400.00',
        'total_offer_discounts': '168.00',
        'delivery_price': '250.00',
        'market_total': '1482.00',
      },
    },
  ],
  'summary': {
    'subtotal': '2975.00',
    'discount_total': '168.00',
    'delivery_total': '250.00',
    'grand_total': '3057.00',
  },
};

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
