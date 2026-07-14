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
  int _previewGeneration = 0;
  int _orderGeneration = 0;

  Future<void> loadPreview({
    required List<CartItemData> cartItems,
    required bool useRemotePreview,
    required String addressId,
    String? paymentMethod,
    String? description,
    String? deliveryNote,
  }) async {
    final trimmedAddressId = addressId.trim();
    final previewUseCase = _previewOrderUseCase;
    if (!useRemotePreview ||
        previewUseCase == null ||
        cartItems.isEmpty ||
        trimmedAddressId.isEmpty) {
      _previewGeneration++;
      if (state.preview != null || state.previewErrorMessage != null) {
        emit(const CheckoutInitial());
      }
      return;
    }

    final generation = ++_previewGeneration;
    emit(CheckoutInitial(isPreviewLoading: true));

    final result = await previewUseCase(
      cartItems: cartItems,
      addressId: trimmedAddressId,
      paymentMethod: paymentMethod,
      description: description,
      deliveryNote: deliveryNote,
    );
    if (generation != _previewGeneration || isClosed) return;

    result.when(
      success: (preview) {
        emit(CheckoutInitial(preview: preview));
      },
      failure: (failure) {
        emit(CheckoutInitial(previewErrorMessage: failure.message));
      },
    );
  }

  Future<void> createOrder({
    required ShippingAddressData shippingAddress,
    required List<OrderItemData> items,
    List<CartItemData> cartItems = const [],
    String? paymentMethod,
    String? deliveryType,
    String? customDeliveryArea,
    String? deliveryAreaId,
    String? description,
    String? deliveryNote,
    double shippingFee = 0,
    double taxTotal = 0,
    double discountTotal = 0,
  }) async {
    if (state is CheckoutLoading) return;

    final generation = ++_orderGeneration;

    emit(
      CheckoutLoading(
        preview: state.preview,
        previewErrorMessage: state.previewErrorMessage,
      ),
    );

    final result = await _createOrderUseCase(
      shippingAddress: shippingAddress,
      items: items,
      cartItems: cartItems,
      paymentMethod: paymentMethod,
      deliveryType: deliveryType,
      customDeliveryArea: customDeliveryArea,
      deliveryAreaId: deliveryAreaId,
      description: description,
      deliveryNote: deliveryNote,
      shippingFee: shippingFee,
      taxTotal: taxTotal,
      discountTotal: discountTotal,
    );
    if (generation != _orderGeneration || isClosed) return;

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
    _previewGeneration++;
    _orderGeneration++;
    emit(const CheckoutInitial());
  }

  void clearPreview() {
    _previewGeneration++;
    emit(const CheckoutInitial());
  }
}
