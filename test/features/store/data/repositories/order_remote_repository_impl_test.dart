import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/checkout_error_messages.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/store/data/repositories/order_remote_repository_impl.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('OrderRemoteRepositoryImpl', () {
    test('uses one authenticated request for preview and create', () async {
      final apiClient = FakeApiClient((request) {
        if (request.path == '/orders/preview/') return _previewPayload;
        if (request.path == '/orders/create/') return _createdOrderPayload;
        return <String, dynamic>{'is_active': true};
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      await repository.previewOrder(
        cartItems: const [_cartItem],
        addressId: _address.id!,
      );
      await repository.createOrder(
        shippingAddress: _address,
        items: const [_item],
        cartItems: const [_cartItem],
      );

      expect(apiClient.requests.map((request) => request.path), [
        '/orders/preview/',
        '/orders/create/',
      ]);
    });

    test('sends POST orders create with cart products and offers', () async {
      late FakeApiRequest capturedRequest;
      final apiClient = FakeApiClient((request) {
        capturedRequest = request;
        return _createdOrderPayload;
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.createOrder(
        shippingAddress: _address,
        items: const [_item],
        cartItems: const [
          CartItemData(
            id: 'cart-1',
            productId: 'product-1',
            variantId: '2',
            image: 'image.png',
            brand: 'Yalla',
            title: 'Fresh product',
            price: 320,
            quantity: 2,
          ),
          CartItemData(
            id: '4',
            productId: '4',
            image: 'offer.png',
            brand: 'Yalla',
            title: 'Bundle offer',
            price: 250,
            quantity: 1,
            itemType: 'offer',
          ),
        ],
        description: 'Leave at door',
        deliveryNote: '',
      );

      result.when(
        success: (orders) => expect(orders.single.paymentMethod, 'cash'),
        failure: (failure) => fail(failure.message),
      );
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.path, '/orders/create/');
      expect(apiClient.requests, hasLength(1));
      expect(capturedRequest.data, {
        'address_id': 12,
        'payment_method': 'cash',
        'description': 'Leave at door',
        'delivery_note': '',
        'items': [
          {'variant_id': 2, 'quantity': 2},
        ],
        'offers': [
          {'offer_id': 4},
        ],
      });
    });

    test('createOrder sends offers as integer offer_id', () async {
      late FakeApiRequest capturedRequest;
      final apiClient = FakeApiClient((request) {
        capturedRequest = request;
        return _createdOrderPayload;
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.createOrder(
        shippingAddress: _address,
        items: const [_item],
        cartItems: const [
          CartItemData(
            id: 'cart-offer',
            productId: 'offer_5',
            image: 'offer.png',
            brand: 'Yalla',
            title: 'Bundle offer',
            price: 250,
            quantity: 1,
            itemType: 'offer',
          ),
        ],
      );

      result.when(success: (_) {}, failure: (failure) => fail(failure.message));
      expect((capturedRequest.data as Map<String, dynamic>)['items'], isEmpty);
      expect((capturedRequest.data as Map<String, dynamic>)['offers'], [
        {'offer_id': 5},
      ]);
    });

    test('createOrder parses object response', () async {
      final apiClient = FakeApiClient((request) => _createdOrderPayload);
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.createOrder(
        shippingAddress: _address,
        items: const [_item],
        cartItems: const [_cartItem],
      );

      result.when(
        success: (orders) {
          final order = orders.single;
          expect(order.id, '9');
          expect(order.total, 1520);
          expect(order.items, hasLength(2));
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('createOrder parses list response with one order', () async {
      final apiClient = FakeApiClient((request) => [_createdOrderPayload]);
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.createOrder(
        shippingAddress: _address,
        items: const [_item],
        cartItems: const [_cartItem],
      );

      result.when(
        success: (orders) => expect(orders.single.id, '9'),
        failure: (failure) => fail(failure.message),
      );
    });

    test(
      'createOrder uses the first order from create response list',
      () async {
        final apiClient = FakeApiClient(
          (request) => [
            _createdOrderPayload,
            {..._createdOrderPayload, 'id': 10},
          ],
        );
        final repository = OrderRemoteRepositoryImpl(apiClient);

        final result = await repository.createOrder(
          shippingAddress: _address,
          items: const [_item],
          cartItems: const [_cartItem],
        );

        result.when(
          success: (orders) {
            expect(orders, hasLength(1));
            expect(orders.single.id, '9');
          },
          failure: (failure) => fail(failure.message),
        );
      },
    );

    test(
      'createOrder parses parent order list response with extra market fields',
      () async {
        final apiClient = FakeApiClient(
          (request) => [
            {
              ..._createdOrderPayload,
              'is_multi_market': true,
              'market_count': 2,
              'market_sections': [
                {'market': 'Fresh Market'},
              ],
            },
          ],
        );
        final repository = OrderRemoteRepositoryImpl(apiClient);

        final result = await repository.createOrder(
          shippingAddress: _address,
          items: const [_item],
          cartItems: const [_cartItem],
        );

        result.when(
          success: (orders) {
            expect(orders, hasLength(1));
            expect(orders.single.id, '9');
          },
          failure: (failure) => fail(failure.message),
        );
      },
    );

    test('createOrder 201 list response returns success', () async {
      final apiClient = FakeApiClient((request) => [_createdOrderPayload]);
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.createOrder(
        shippingAddress: _address,
        items: const [_item],
        cartItems: const [_cartItem],
      );

      result.when(
        success: (orders) => expect(orders.single.status, OrderStatus.pending),
        failure: (failure) => fail(failure.message),
      );
    });

    test('createOrder parses nested order payloads', () async {
      final responses = [
        {'order': _createdOrderPayload},
        {'data': _createdOrderPayload},
        {
          'result': [_createdOrderPayload],
        },
      ];

      for (final response in responses) {
        final apiClient = FakeApiClient((request) => response);
        final repository = OrderRemoteRepositoryImpl(apiClient);

        final result = await repository.createOrder(
          shippingAddress: _address,
          items: const [_item],
          cartItems: const [_cartItem],
        );

        result.when(
          success: (orders) => expect(orders.single.id, '9'),
          failure: (failure) => fail(failure.message),
        );
      }
    });

    test(
      'createOrder parser failure does not say could not load orders',
      () async {
        final apiClient = FakeApiClient((request) => {'detail': 'Created'});
        final repository = OrderRemoteRepositoryImpl(apiClient);

        final result = await repository.createOrder(
          shippingAddress: _address,
          items: const [_item],
          cartItems: const [_cartItem],
        );

        result.when(
          success: (_) => fail('Expected parser failure.'),
          failure: (failure) {
            expect(failure.message, 'Could not create order');
            expect(failure.message, isNot('Could not load orders.'));
          },
        );
      },
    );

    test(
      'does not call create API when product item is missing variant',
      () async {
        final apiClient = FakeApiClient((request) {
          fail('API should not be called for invalid cart items.');
        });
        final repository = OrderRemoteRepositoryImpl(apiClient);

        final result = await repository.createOrder(
          shippingAddress: _address,
          items: const [],
          cartItems: const [
            CartItemData(
              id: 'cart-1',
              image: 'image.png',
              brand: 'Yalla',
              title: 'Fresh product',
              price: 320,
              quantity: 2,
            ),
          ],
        );

        result.when(
          success: (_) => fail('Expected validation failure.'),
          failure: (failure) => expect(
            failure.message,
            'Some cart items are missing variant information. Please add them again.',
          ),
        );
        expect(apiClient.requests, isEmpty);
      },
    );

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
        addressId: '12',
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
      expect(apiClient.requests, hasLength(1));
      expect(capturedRequest.data, {
        'address_id': 12,
        'payment_method': 'cash',
        'description': '',
        'delivery_note': '',
        'items': [
          {'variant_id': 23, 'quantity': 2},
        ],
        'offers': [],
      });
    });

    test('previewOrder sends offers as integer offer_id', () async {
      late FakeApiRequest capturedRequest;
      final apiClient = FakeApiClient((request) {
        capturedRequest = request;
        return _previewPayload;
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.previewOrder(
        addressId: '12',
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
          CartItemData(
            id: 'offer-row',
            productId: 'offer-5',
            image: 'offer.png',
            brand: 'Yalla',
            title: 'Bundle offer',
            price: 250,
            quantity: 1,
            itemType: 'offer',
          ),
        ],
      );

      result.when(success: (_) {}, failure: (failure) => fail(failure.message));
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.path, '/orders/preview/');
      expect((capturedRequest.data as Map<String, dynamic>)['items'], [
        {'variant_id': 23, 'quantity': 2},
      ]);
      expect((capturedRequest.data as Map<String, dynamic>)['offers'], [
        {'offer_id': 5},
      ]);
    });

    test('string offer id becomes int', () async {
      late FakeApiRequest capturedRequest;
      final apiClient = FakeApiClient((request) {
        capturedRequest = request;
        return _previewPayload;
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.previewOrder(
        addressId: '12',
        cartItems: const [
          CartItemData(
            id: '5',
            productId: '5',
            image: 'offer.png',
            brand: 'Yalla',
            title: 'Bundle offer',
            price: 250,
            quantity: 1,
            itemType: 'offer',
          ),
        ],
      );

      result.when(success: (_) {}, failure: (failure) => fail(failure.message));
      expect((capturedRequest.data as Map<String, dynamic>)['offers'], [
        {'offer_id': 5},
      ]);
    });

    test('invalid offer id returns failure and does not call API', () async {
      final apiClient = FakeApiClient((request) {
        fail('API should not be called for invalid offer ids.');
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.previewOrder(
        addressId: '12',
        cartItems: const [
          CartItemData(
            id: 'offer-five',
            image: 'offer.png',
            brand: 'Yalla',
            title: 'Bundle offer',
            price: 250,
            quantity: 1,
            itemType: 'offer',
          ),
        ],
      );

      result.when(
        success: (_) => fail('Expected validation failure.'),
        failure: (failure) => expect(
          failure.message,
          'Some offer items are missing valid offer information. Please add them again.',
        ),
      );
      expect(apiClient.requests, isEmpty);
    });

    test(
      'createOrder invalid offer id returns failure and does not call API',
      () async {
        final apiClient = FakeApiClient((request) {
          fail('API should not be called for invalid offer ids.');
        });
        final repository = OrderRemoteRepositoryImpl(apiClient);

        final result = await repository.createOrder(
          shippingAddress: _address,
          items: const [_item],
          cartItems: const [
            CartItemData(
              id: 'bundle-five',
              image: 'offer.png',
              brand: 'Yalla',
              title: 'Bundle offer',
              price: 250,
              quantity: 1,
              itemType: 'offer',
            ),
          ],
        );

        result.when(
          success: (_) => fail('Expected validation failure.'),
          failure: (failure) => expect(
            failure.message,
            'Some offer items are missing valid offer information. Please add them again.',
          ),
        );
        expect(apiClient.requests, isEmpty);
      },
    );

    test(
      'previewOrder empty cart returns failure and does not call API',
      () async {
        final apiClient = FakeApiClient((request) {
          fail('API should not be called for an empty checkout payload.');
        });
        final repository = OrderRemoteRepositoryImpl(apiClient);

        final result = await repository.previewOrder(
          addressId: '12',
          cartItems: const [],
        );

        result.when(
          success: (_) => fail('Expected validation failure.'),
          failure: (failure) => expect(
            failure.message,
            'Add at least one product or offer before checkout.',
          ),
        );
        expect(apiClient.requests, isEmpty);
      },
    );

    test('previewOrder invalid quantity returns failure before API', () async {
      final apiClient = FakeApiClient((request) {
        fail('API should not be called for invalid quantities.');
      });
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.previewOrder(
        addressId: '12',
        cartItems: const [
          CartItemData(
            id: 'cart-1',
            variantId: '23',
            image: 'image.png',
            brand: 'Yalla',
            title: 'Fresh product',
            price: 700,
            quantity: 0,
          ),
        ],
      );

      result.when(
        success: (_) => fail('Expected validation failure.'),
        failure: (failure) => expect(
          failure.message,
          'Cart items must have a quantity greater than zero.',
        ),
      );
      expect(apiClient.requests, isEmpty);
    });

    test('maps checkout validation errors to Arabic safe messages', () async {
      final cases = [
        (
          name: 'region',
          data: {
            'requires_region_selection': ['True'],
            'message': ['Select a market browsing region before checkout.'],
            'current_selection': ['None'],
          },
          message: checkoutRegionRequiredMessage,
        ),
        (
          name: 'address',
          data: {
            'requires_address_selection': ['True'],
            'address_id': ['Choose an address.'],
          },
          message: checkoutAddressRequiredMessage,
        ),
        (
          name: 'payment',
          data: {
            'payment_method': ['This field is required.'],
          },
          message: checkoutPaymentRequiredMessage,
        ),
        (
          name: 'items',
          data: {
            'items': ['Invalid pk "999999" - object does not exist.'],
          },
          message: checkoutItemsInvalidMessage,
        ),
        (
          name: 'offers',
          data: {
            'offers': ['لا يمكن استخدام عرض مدينة داخل طلب عام'],
          },
          message: 'لا يمكن استخدام عرض مدينة داخل طلب عام',
        ),
        (
          name: 'non field',
          data: {
            'non_field_errors': ['This field is required.'],
          },
          message: checkoutOrderInvalidMessage,
        ),
      ];

      for (final entry in cases) {
        final apiClient = FakeApiClient((request) {
          throw _dioValidationError(request.path, entry.data);
        });
        final repository = OrderRemoteRepositoryImpl(apiClient);

        final result = await repository.previewOrder(
          addressId: '12',
          cartItems: const [_cartItem],
        );

        result.when(
          success: (_) => fail('Expected ${entry.name} failure.'),
          failure: (failure) => expect(failure.message, entry.message),
        );
      }
    });

    test('parses preview summary', () async {
      final apiClient = FakeApiClient((request) => _previewPayload);
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.previewOrder(
        addressId: '12',
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

    test('parses fixed-area two-market preview response', () async {
      final apiClient = FakeApiClient(
        (request) => _twoMarketFixedAreaPreviewPayload,
      );
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.previewOrder(
        addressId: '12',
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
          expect(preview.isMultiMarket, isTrue);
          expect(preview.marketCount, 2);
          expect(preview.serviceCity?['name'], 'Cairo');
          expect(preview.orderScope, 'service_city');
          expect(preview.marketNamesSummary, 'Fresh Market, Daily Market');
          expect(preview.marketGroups, hasLength(2));
          expect(preview.marketGroups.first.marketName, 'Fresh Market');
          expect(preview.marketGroups.first.isFixedAreaDelivery, isTrue);
          expect(preview.marketGroups.first.deliveryPrice, 120);
          expect(preview.marketGroups.first.pricing.deliveryPrice, 120);
          expect(preview.marketGroups.first.selectedProducts, hasLength(1));
          expect(preview.marketGroups.first.selectedOffers, hasLength(1));
          expect(preview.marketGroups.last.marketName, 'Daily Market');
          expect(preview.marketGroups.last.deliveryType, 'fixed_area');
          expect(preview.marketGroups.last.deliveryPrice, isNull);
          expect(preview.marketGroups.last.pricing.deliveryPrice, isNull);
          expect(preview.marketGroups.last.isPendingDeliveryQuote, isFalse);
          expect(preview.hasPendingDeliveryQuote, isFalse);
          expect(preview.summary.grandTotal, 1580);
          expect(preview.hasUnavailableDelivery, isFalse);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('parses pending-delivery two-market preview response', () async {
      final apiClient = FakeApiClient(
        (request) => _twoMarketPendingDeliveryPreviewPayload,
      );
      final repository = OrderRemoteRepositoryImpl(apiClient);

      final result = await repository.previewOrder(
        addressId: '12',
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
          expect(preview.isMultiMarket, isTrue);
          expect(preview.marketCount, 2);
          expect(preview.marketGroups, hasLength(2));
          expect(
            preview.marketGroups.every(
              (group) =>
                  group.deliveryType == 'delivery' &&
                  group.deliveryPrice == null &&
                  group.isPendingDeliveryQuote,
            ),
            isTrue,
          );
          expect(preview.hasPendingDeliveryQuote, isTrue);
          expect(preview.hasUnavailableDelivery, isFalse);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('order delivery status follows delivery type', () {
      final fixedAreaOrder = OrderData.fromJson({
        ..._createdOrderPayload,
        'delivery_type': 'fixed_area',
        'delivery_price': null,
      });
      final deliveryOrder = OrderData.fromJson({
        ..._createdOrderPayload,
        'delivery_type': 'delivery',
        'delivery_price': null,
      });
      final manualQuoteOrder = OrderData.fromJson({
        ..._createdOrderPayload,
        'delivery_type': 'manual_quote',
        'delivery_price': null,
      });

      expect(
        fixedAreaOrder.deliveryPriceStatus,
        OrderDeliveryPriceStatus.fixed,
      );
      expect(
        deliveryOrder.deliveryPriceStatus,
        OrderDeliveryPriceStatus.pendingQuote,
      );
      expect(
        manualQuoteOrder.deliveryPriceStatus,
        OrderDeliveryPriceStatus.pendingQuote,
      );
    });

    test('maps production lifecycle statuses to customer-facing states', () {
      final assigned = OrderData.fromJson({
        ..._createdOrderPayload,
        'status': 'assigned',
      });
      final pickedUp = OrderData.fromJson({
        ..._createdOrderPayload,
        'status': 'picked_up',
      });
      final delivered = OrderData.fromJson({
        ..._createdOrderPayload,
        'status': 'delivered',
      });

      expect(assigned.status, OrderStatus.processing);
      expect(assigned.statusLabel, 'Preparing');
      expect(pickedUp.status, OrderStatus.shipped);
      expect(pickedUp.statusLabel, 'Shipment on the way');
      expect(delivered.status, OrderStatus.delivered);
      expect(delivered.statusLabel, 'Delivered');
    });

    test('uses the picked-up transition as the shipping date', () {
      final order = OrderData.fromJson({
        ..._createdOrderPayload,
        'status': 'delivered',
        'estimated_delivery_at': null,
        'assigned_at': '2026-07-14T10:23:21.741507Z',
        'delivered_at': '2026-07-14T10:24:45.647947Z',
        'history': [
          {
            'from_status': 'assigned',
            'to_status': 'picked_up',
            'created_at': '2026-07-14T10:24:05.455629Z',
          },
          {
            'from_status': 'picked_up',
            'to_status': 'delivered',
            'created_at': '2026-07-14T10:24:45.652188Z',
          },
        ],
      });

      expect(
        order.estimatedDeliveryAt,
        DateTime.parse('2026-07-14T10:24:05.455629Z'),
      );
    });

    test('normalizes market pickup statuses before presentation', () {
      expect(
        const OrderMarketSectionData(
          marketId: '1',
          marketName: 'Market',
          pickupStatus: 'picked_up',
        ).pickupStatusLabel,
        'Picked up',
      );
      expect(
        const OrderMarketSectionData(
          marketId: '1',
          marketName: 'Market',
          pickupStatus: 'unknown_backend_value',
        ).pickupStatusLabel,
        'Status updated',
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

const _twoMarketFixedAreaPreviewPayload = {
  'addresses': [
    {'id': 1, 'name': 'Home'},
  ],
  'selected_address': {'id': 1, 'name': 'Home'},
  'service_city': {'id': 10, 'name': 'Cairo'},
  'order_scope': 'service_city',
  'is_multi_market': true,
  'market_count': 2,
  'market_names_summary': 'Fresh Market, Daily Market',
  'market_groups': [
    {
      'market': {'id': 5, 'name': 'Fresh Market'},
      'service_city': {'id': 10, 'name': 'Cairo'},
      'delivery_area': {'id': 2, 'name': 'Downtown'},
      'delivery_type': 'fixed_area',
      'delivery_price': '120.00',
      'delivery_message': '',
      'delivery_available': true,
      'selected_products': [
        {'id': 1, 'name': 'Tomatoes'},
      ],
      'selected_offers': [
        {'id': 3, 'name': 'Bundle'},
      ],
      'pricing': {
        'products_subtotal': '1000.00',
        'total_offer_discounts': '100.00',
        'delivery_price': '120.00',
        'market_total': '1020.00',
      },
    },
    {
      'market': {'id': 8, 'name': 'Daily Market'},
      'service_city': {'id': 10, 'name': 'Cairo'},
      'delivery_area': {'id': 2, 'name': 'Downtown'},
      'delivery_type': 'fixed_area',
      'delivery_price': null,
      'delivery_message': '',
      'delivery_available': true,
      'selected_products': [],
      'selected_offers': [],
      'pricing': {
        'products_subtotal': '700.00',
        'total_offer_discounts': '140.00',
        'delivery_price': null,
        'market_total': '560.00',
      },
    },
  ],
  'summary': {
    'subtotal': '1700.00',
    'discount_total': '240.00',
    'delivery_total': '120.00',
    'grand_total': '1580.00',
  },
};

const _twoMarketPendingDeliveryPreviewPayload = {
  'addresses': [
    {'id': 1, 'name': 'Home'},
  ],
  'selected_address': {'id': 1, 'name': 'Home'},
  'service_city': {'id': 10, 'name': 'Cairo'},
  'order_scope': 'service_city',
  'is_multi_market': true,
  'market_count': 2,
  'market_names_summary': 'Fresh Market, Daily Market',
  'market_groups': [
    {
      'market': {'id': 5, 'name': 'Fresh Market'},
      'service_city': {'id': 10, 'name': 'Cairo'},
      'delivery_area': {'id': 2, 'name': 'Downtown'},
      'delivery_type': 'delivery',
      'delivery_price': null,
      'delivery_message': 'Delivery price will be determined later.',
      'delivery_available': true,
      'selected_products': [
        {'id': 1, 'name': 'Tomatoes'},
      ],
      'selected_offers': [
        {'id': 3, 'name': 'Bundle'},
      ],
      'pricing': {
        'products_subtotal': '1000.00',
        'total_offer_discounts': '100.00',
        'delivery_price': null,
        'market_total': '900.00',
      },
    },
    {
      'market': {'id': 8, 'name': 'Daily Market'},
      'service_city': {'id': 10, 'name': 'Cairo'},
      'delivery_area': {'id': 2, 'name': 'Downtown'},
      'delivery_type': 'delivery',
      'delivery_price': null,
      'delivery_message': 'Delivery price will be determined later.',
      'delivery_available': true,
      'selected_products': [],
      'selected_offers': [],
      'pricing': {
        'products_subtotal': '700.00',
        'total_offer_discounts': '140.00',
        'delivery_price': null,
        'market_total': '560.00',
      },
    },
  ],
  'summary': {
    'subtotal': '1700.00',
    'discount_total': '240.00',
    'delivery_total': null,
    'grand_total': '1460.00',
  },
};

const _createdOrderPayload = {
  'id': 9,
  'user_id': 2,
  'delivery_address_id': 1,
  'market_id': 2,
  'payment_method': 'cash',
  'discount': '0.00',
  'description': '',
  'status': 'pending',
  'delivery_price': '250.00',
  'subtotal_price': '1270.00',
  'total_price': '1520.00',
  'items': [
    {'id': 15, 'variant_id': 13, 'quantity': 1, 'unit_price': '420.00'},
    {'id': 16, 'variant_id': 11, 'quantity': 1, 'unit_price': '850.00'},
  ],
  'offers': [],
  'created_at': '2026-07-01T23:54:53.440326Z',
  'updated_at': '2026-07-01T23:54:53.440346Z',
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

const _cartItem = CartItemData(
  id: 'cart-1',
  productId: 'product-1',
  variantId: '13',
  image: 'image.png',
  brand: 'Yalla',
  title: 'Fresh product',
  price: 420,
  quantity: 1,
);

DioException _dioValidationError(String path, Object? data) {
  final requestOptions = RequestOptions(path: path);
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: requestOptions,
      statusCode: 400,
      data: data,
    ),
  );
}
