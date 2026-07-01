import '../../domain/entities/order.dart';
import '../../domain/entities/order_preview.dart';

sealed class CheckoutState {
  const CheckoutState({
    this.preview,
    this.previewErrorMessage,
    this.isPreviewLoading = false,
  });

  final OrderPreviewData? preview;
  final String? previewErrorMessage;
  final bool isPreviewLoading;
}

final class CheckoutInitial extends CheckoutState {
  const CheckoutInitial({
    super.preview,
    super.previewErrorMessage,
    super.isPreviewLoading,
  });
}

final class CheckoutLoading extends CheckoutState {
  const CheckoutLoading({
    super.preview,
    super.previewErrorMessage,
    super.isPreviewLoading,
  });
}

final class CheckoutSuccess extends CheckoutState {
  const CheckoutSuccess(this.order, {super.preview, super.previewErrorMessage});

  final OrderData order;
}

final class CheckoutFailure extends CheckoutState {
  const CheckoutFailure(
    this.message, {
    super.preview,
    super.previewErrorMessage,
  });

  final String message;
}
