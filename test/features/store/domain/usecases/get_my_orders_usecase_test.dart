import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_my_orders_usecase.dart';

void main() {
  test(
    'uses the configured fallback only when repository data is empty',
    () async {
      final fallback = _order('fallback');
      final useCase = GetMyOrdersUseCase(
        _OrderRepository(const ApiResult.success([])),
        supplement: _Supplement([fallback]),
      );

      final result = await useCase();

      expect((result as ApiSuccess<List<OrderData>>).data, [same(fallback)]);
    },
  );

  test('keeps repository orders ahead of fallback data', () async {
    final stored = _order('stored');
    final useCase = GetMyOrdersUseCase(
      _OrderRepository(ApiResult.success([stored])),
      supplement: _Supplement([_order('fallback')]),
    );

    final result = await useCase();

    expect((result as ApiSuccess<List<OrderData>>).data, [same(stored)]);
  });

  test('does not hide repository failures with fallback data', () async {
    final useCase = GetMyOrdersUseCase(
      _OrderRepository(
        const ApiResult.failure(UnknownFailure('Orders unavailable.')),
      ),
      supplement: _Supplement([_order('fallback')]),
    );

    final result = await useCase();

    expect(result, isA<ApiFailure<List<OrderData>>>());
  });
}

OrderData _order(String id) {
  return OrderData(
    id: id,
    orderNumber: id,
    status: OrderStatus.pending,
    placedAt: DateTime(2026),
    shippingAddress: const ShippingAddressData(
      fullName: '',
      phone: '',
      line1: '',
      city: '',
      state: '',
      country: '',
      postalCode: '',
    ),
    paymentMethod: 'cash',
    items: const [],
    subtotal: 0,
    shippingFee: 0,
    taxTotal: 0,
    discountTotal: 0,
    total: 0,
  );
}

class _Supplement implements OrderHistorySupplement {
  const _Supplement(this.orders);

  final List<OrderData> orders;

  @override
  List<OrderData> fallbackOrders() => orders;
}

class _OrderRepository implements OrderRepository {
  const _OrderRepository(this.result);

  final ApiResult<List<OrderData>> result;

  @override
  Future<ApiResult<List<OrderData>>> getMyOrders() async => result;

  @override
  Future<ApiResult<List<OrderData>>> createOrder({
    required ShippingAddressData shippingAddress,
    required List<OrderItemData> items,
    List<CartItemData> cartItems = const [],
    String? paymentMethod,
    String? deliveryType,
    String? customDeliveryArea,
    String? deliveryAreaId,
    int? shippingCompanyId,
    String? description,
    String? deliveryNote,
    double shippingFee = 0,
    double taxTotal = 0,
    double discountTotal = 0,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<OrderData>> acceptDeliveryQuote(String orderId) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<OrderPreviewData>> previewOrder({
    required List<CartItemData> cartItems,
    required String addressId,
    String? paymentMethod,
    String? description,
    String? deliveryNote,
  }) => throw UnimplementedError();
}
