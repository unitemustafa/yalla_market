import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/preview_order_usecase.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this._createOrderUseCase, [this._previewOrderUseCase])
    : super(const CheckoutInitial());

  final CreateOrderUseCase _createOrderUseCase;
  final PreviewOrderUseCase? _previewOrderUseCase;

  Future<void> loadPreview({
    required List<CartItemData> cartItems,
    required bool useRemotePreview,
  }) async {
    final previewUseCase = _previewOrderUseCase;
    if (!useRemotePreview || previewUseCase == null || cartItems.isEmpty) {
      if (state.preview != null || state.previewErrorMessage != null) {
        emit(const CheckoutInitial());
      }
      return;
    }

    emit(
      CheckoutInitial(
        preview: state.preview,
        previewErrorMessage: state.previewErrorMessage,
        isPreviewLoading: true,
      ),
    );

    final result = await previewUseCase(cartItems: cartItems);
    result.when(
      success: (preview) {
        emit(CheckoutInitial(preview: preview));
      },
      failure: (failure) {
        emit(
          CheckoutInitial(
            preview: state.preview,
            previewErrorMessage: failure.message,
          ),
        );
      },
    );
  }

  Future<void> createOrder({
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
    if (state is CheckoutLoading) return;

    emit(
      CheckoutLoading(
        preview: state.preview,
        previewErrorMessage: state.previewErrorMessage,
      ),
    );

    final result = await _createOrderUseCase(
      shippingAddress: shippingAddress,
      items: items,
      paymentMethod: paymentMethod,
      deliveryType: deliveryType,
      customDeliveryArea: customDeliveryArea,
      deliveryAreaId: deliveryAreaId,
      shippingFee: shippingFee,
      taxTotal: taxTotal,
      discountTotal: discountTotal,
    );
    result.when(
      success: (order) {
        emit(
          CheckoutSuccess(
            order,
            preview: state.preview,
            previewErrorMessage: state.previewErrorMessage,
          ),
        );
      },
      failure: (failure) {
        emit(
          CheckoutFailure(
            failure.message,
            preview: state.preview,
            previewErrorMessage: state.previewErrorMessage,
          ),
        );
      },
    );
  }

  void reset() {
    emit(const CheckoutInitial());
  }
}
