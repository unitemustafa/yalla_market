import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/create_order_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/preview_order_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/checkout_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/checkout_state.dart';

import '../../../../helpers/domain_fixtures.dart';

void main() {
  group('CheckoutCubit', () {
    test('creates a cash on delivery order successfully', () async {
      final repository = _FakeOrderRepository(createResult: sampleOrder);
      final cubit = CheckoutCubit(
        CreateOrderUseCase(repository),
        PreviewOrderUseCase(repository),
      );
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<CheckoutLoading>(), isA<CheckoutSuccess>()]),
      );

      await cubit.createOrder(
        shippingAddress: sampleShippingAddress,
        items: const [sampleOrderItem],
        paymentMethod: 'cash_on_delivery',
        shippingFee: 50,
      );

      expect(repository.lastPaymentMethod, 'cash_on_delivery');
      expect((cubit.state as CheckoutSuccess).order.id, sampleOrder.id);
      await expectedStates;
      await cubit.close();
    });

    test('emits failure when order creation is rejected', () async {
      final repository = _FakeOrderRepository(
        createFailure: const ValidationFailure('Unsupported payment method.'),
      );
      final cubit = CheckoutCubit(
        CreateOrderUseCase(repository),
        PreviewOrderUseCase(repository),
      );
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<CheckoutLoading>(), isA<CheckoutFailure>()]),
      );

      await cubit.createOrder(
        shippingAddress: sampleShippingAddress,
        items: const [sampleOrderItem],
        paymentMethod: 'card',
      );

      expect(
        (cubit.state as CheckoutFailure).message,
        'Unsupported payment method.',
      );
      await expectedStates;
      await cubit.close();
    });

    test('resets back to the initial state', () async {
      final repository = _FakeOrderRepository(createResult: sampleOrder);
      final cubit = CheckoutCubit(
        CreateOrderUseCase(repository),
        PreviewOrderUseCase(repository),
      );
      await cubit.createOrder(
        shippingAddress: sampleShippingAddress,
        items: const [sampleOrderItem],
      );

      cubit.reset();

      expect(cubit.state, isA<CheckoutInitial>());
      await cubit.close();
    });

    test('loads checkout preview successfully', () async {
      final repository = _FakeOrderRepository(previewResult: samplePreview);
      final cubit = CheckoutCubit(
        CreateOrderUseCase(repository),
        PreviewOrderUseCase(repository),
      );
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CheckoutInitial>().having(
            (state) => state.isPreviewLoading,
            'isPreviewLoading',
            isTrue,
          ),
          isA<CheckoutInitial>().having(
            (state) => state.preview?.summary.grandTotal,
            'grandTotal',
            3057,
          ),
        ]),
      );

      await cubit.loadPreview(
        cartItems: const [sampleCartItemWithVariant],
        useRemotePreview: true,
      );

      expect(cubit.state.preview?.summary.grandTotal, 3057);
      await expectedStates;
      await cubit.close();
    });

    test('keeps checkout usable when preview fails', () async {
      final repository = _FakeOrderRepository(
        previewFailure: const ServerFailure('Preview unavailable.'),
      );
      final cubit = CheckoutCubit(
        CreateOrderUseCase(repository),
        PreviewOrderUseCase(repository),
      );

      await cubit.loadPreview(
        cartItems: const [sampleCartItemWithVariant],
        useRemotePreview: true,
      );

      expect(cubit.state, isA<CheckoutInitial>());
      expect(cubit.state.preview, isNull);
      expect(cubit.state.previewErrorMessage, 'Preview unavailable.');
      await cubit.close();
    });
  });
}

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository({
    this.createResult,
    this.createFailure,
    this.previewResult,
    this.previewFailure,
  });

  final OrderData? createResult;
  final Failure? createFailure;
  final OrderPreviewData? previewResult;
  final Failure? previewFailure;
  String? lastPaymentMethod;

  @override
  Future<ApiResult<OrderData>> createOrder({
    required ShippingAddressData shippingAddress,
    required List<OrderItemData> items,
    String? paymentMethod,
    String? deliveryType,
    String? customDeliveryArea,
    String? deliveryAreaId,
    double shippingFee = 0,
    double taxTotal = 0,
    double discountTotal = 0,
  }) async {
    lastPaymentMethod = paymentMethod;

    if (createFailure case final failure?) {
      return ApiResult.failure(failure);
    }

    return ApiResult.success(createResult ?? sampleOrder);
  }

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async {
    return ApiResult.success([sampleOrder]);
  }

  @override
  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
  }) async {
    if (previewFailure case final failure?) {
      return ApiResult.failure(failure);
    }

    return ApiResult.success(previewResult ?? samplePreview);
  }
}

const sampleCartItemWithVariant = CartItemData(
  id: 'cart_1',
  variantId: '23',
  image: 'shoe.png',
  brand: 'Yalla',
  title: 'Running Shoe',
  price: 1200,
  quantity: 1,
);

const samplePreview = OrderPreviewData(
  marketGroups: [
    OrderPreviewMarketGroupData(
      deliveryAvailable: true,
      pricing: OrderPreviewPricingData(
        productsSubtotal: 2975,
        totalOfferDiscounts: 168,
        deliveryPrice: 250,
        marketTotal: 3057,
      ),
    ),
  ],
  summary: OrderPreviewSummaryData(
    subtotal: 2975,
    discountTotal: 168,
    deliveryTotal: 250,
    grandTotal: 3057,
  ),
);
