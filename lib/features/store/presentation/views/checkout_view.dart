import 'package:yalla_market/core/constants/app_constants.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/errors/checkout_error_messages.dart';
import '../../../../core/formatters/app_currency.dart';
import '../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../location/domain/entities/city_data.dart';
import '../../../location/presentation/cubit/location_cubit.dart';
import '../../../personalization/domain/entities/address.dart';
import '../../../personalization/presentation/cubit/address_cubit.dart';
import '../../../personalization/presentation/cubit/address_state.dart';
import '../../../personalization/presentation/views/address/address_region_matcher.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_preview.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../cubit/order_history_cubit.dart';

part 'checkout_review_items.dart';
part 'checkout_order_summary.dart';
part 'checkout_delivery_sections.dart';
part 'checkout_action_and_shared.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key, this.useDemoRepositories});

  final bool? useDemoRepositories;

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  String? _lastPreviewKey;
  bool _isSelectingRegion = false;

  static const _checkoutPaymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AddressCubit>().loadAddresses();
    });
  }

  bool get _useDemoRepositories =>
      widget.useDemoRepositories ?? AppEnvironment.useDemoRepositories;

  double _subtotal(List<CartItemData> items) {
    return items.fold(0, (sum, item) => sum + item.price * item.quantity);
  }

  int _itemCount(List<CartItemData> items) {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  void _loadPreviewIfNeeded(
    BuildContext context,
    List<CartItemData> cartItems,
    AddressData? selectedAddress,
    CityData? selectedCity,
  ) {
    if (_useDemoRepositories) return;
    if (cartItems.isEmpty) {
      _clearPreviewIfNeeded(context);
      return;
    }
    if (selectedCity == null) {
      _clearPreviewIfNeeded(context);
      return;
    }
    if (selectedAddress == null || selectedAddress.id.trim().isEmpty) {
      _clearPreviewIfNeeded(context);
      return;
    }

    final cartFingerprint = cartItems
        .map(
          (item) =>
              '${item.id}:${item.variantId}:${item.productId}:${item.quantity}:${item.price}:${item.itemType}',
        )
        .join('|');
    final previewKey = [
      cartFingerprint,
      selectedAddress.id,
      selectedAddress.serviceCityId,
      selectedAddress.deliveryAreaId,
      selectedAddress.manualCity,
      selectedAddress.manualArea,
      selectedAddress.deliveryType,
      selectedAddress.deliveryAreaPrice,
      selectedCity.slug,
      selectedCity.serviceCityId,
    ].join('|');
    if (previewKey == _lastPreviewKey) return;
    _lastPreviewKey = previewKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CheckoutCubit>().loadPreview(
        cartItems: cartItems,
        useRemotePreview: true,
        addressId: selectedAddress.id,
        paymentMethod: _checkoutPaymentMethod,
        description: '',
        deliveryNote: '',
      );
    });
  }

  void _clearPreviewIfNeeded(BuildContext context) {
    final checkoutState = context.read<CheckoutCubit>().state;
    if (_lastPreviewKey == null &&
        checkoutState.preview == null &&
        checkoutState.previewErrorMessage == null &&
        !checkoutState.isPreviewLoading) {
      return;
    }
    _lastPreviewKey = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CheckoutCubit>().clearPreview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          previous.previewErrorMessage != current.previewErrorMessage,
      listener: (context, state) {
        if (state is CheckoutSuccess) {
          final createdOrder = state.order;
          if (createdOrder == null) return;
          CustomSnackBar.showSuccess(
            context: context,
            title: 'Order confirmed',
            message: 'Your order has been created successfully.',
          );
          unawaited(context.read<CartCubit>().clearLocalCart());
          context.read<CheckoutCubit>().reset();
          unawaited(context.read<OrderHistoryCubit>().loadOrders(force: true));
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.paymentSuccess,
            arguments: _paymentSuccessArgs(createdOrder),
          );
        }

        if (state is CheckoutFailure) {
          if (isCheckoutRegionRequiredMessage(state.message)) {
            unawaited(_selectRegionForCheckoutAndRetry(context));
            return;
          }
          CustomSnackBar.showError(
            context: context,
            title: 'Order confirmation failed',
            message: state.message,
          );
        }

        if (isCheckoutRegionRequiredMessage(state.previewErrorMessage)) {
          unawaited(_selectRegionForCheckoutAndRetry(context));
        }
      },
      builder: (context, checkoutState) {
        return BlocBuilder<CartCubit, List<CartItemData>>(
          builder: (context, cartItems) {
            return BlocBuilder<AddressCubit, AddressState>(
              builder: (context, addressState) {
                final selectedCity = context
                    .watch<LocationCubit>()
                    .state
                    .selectedCity;
                final selectedAddress = selectedAvailableAddressForCity(
                  addresses: addressState.addresses,
                  selectedAddressId: addressState.selectedAddressId,
                  selectedCity: selectedCity,
                );
                _loadPreviewIfNeeded(
                  context,
                  cartItems,
                  selectedAddress,
                  selectedCity,
                );
                final hasSavedAddress = selectedAddress != null;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final backgroundColor = isDark
                    ? AppColors.darkBackground
                    : const Color(0xFFF7F8FB);
                final localSubtotal = _subtotal(cartItems);
                final preview = checkoutState.preview;
                final previewSummary = preview?.summary;
                final isRemotePreviewLoading = checkoutState.isPreviewLoading;
                final hasPreviewTotals =
                    _useDemoRepositories ||
                    (hasSavedAddress &&
                        !isRemotePreviewLoading &&
                        previewSummary != null);
                final subtotal = previewSummary?.subtotal ?? localSubtotal;
                final discount = hasPreviewTotals
                    ? previewSummary?.discountTotal ?? 0.0
                    : 0.0;
                final shippingFee = hasPreviewTotals
                    ? previewSummary?.deliveryTotal ?? 0.0
                    : 0.0;
                final total = hasPreviewTotals
                    ? previewSummary?.grandTotal ?? localSubtotal
                    : localSubtotal;
                final hasPendingDeliveryQuote =
                    preview?.hasPendingDeliveryQuote ?? false;
                final totalLabel = hasPreviewTotals ? _formatMoney(total) : '';
                final pendingTotalDeliveryTypeLabel =
                    hasPreviewTotals && hasPendingDeliveryQuote
                    ? _deliveryTypeLabel(context, preview)
                    : null;
                final shippingFeeLabel = hasSavedAddress
                    ? (hasPreviewTotals && !hasPendingDeliveryQuote
                          ? _formatMoney(shippingFee)
                          : _notSpecifiedLabel(context))
                    : '';
                final deliveryTypeLabel = _deliveryTypeLabel(context, preview);
                final reviewItems = hasPreviewTotals && preview != null
                    ? _reviewItemsFromPreview(cartItems, preview)
                    : cartItems;
                final discountLabel = _discountSummaryLabel(context, preview);
                final hasUnavailableDelivery =
                    preview?.hasUnavailableDelivery ?? false;
                final canConfirmRemoteOrder =
                    _useDemoRepositories ||
                    (hasPreviewTotals &&
                        !isRemotePreviewLoading &&
                        !hasUnavailableDelivery);

                return Scaffold(
                  backgroundColor: backgroundColor,
                  body: SafeArea(
                    child: cartItems.isEmpty
                        ? Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                                child: PageTopBar(
                                  title: 'Order Review',
                                  subtitle: 'Confirm items and payment',
                                ),
                              ),
                              Expanded(
                                child: _EmptyCheckoutState(isDark: isDark),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const PageTopBar(
                                  title: 'Order Review',
                                  subtitle: 'Confirm items and payment',
                                ),
                                const SizedBox(height: 18),
                                _ReviewItemsSection(
                                  items: reviewItems,
                                  itemCount: _itemCount(reviewItems),
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 14),
                                _OrderSummaryCard(
                                  subtotal: subtotal,
                                  deliveryTypeLabel: deliveryTypeLabel,
                                  discount: discount,
                                  discountLabel: discountLabel,
                                  shippingFeeLabel: shippingFeeLabel,
                                  totalLabel: totalLabel,
                                  isDark: isDark,
                                ),
                                if (checkoutState.previewErrorMessage !=
                                    null) ...[
                                  const SizedBox(height: 10),
                                  _CheckoutNotice(
                                    message:
                                        isCheckoutRegionRequiredMessage(
                                          checkoutState.previewErrorMessage,
                                        )
                                        ? checkoutRegionRequiredMessage
                                        : 'Could not refresh order totals. Try again.',
                                    isDark: isDark,
                                    isBlocking: true,
                                  ),
                                ],
                                if (isRemotePreviewLoading) ...[
                                  const SizedBox(height: 10),
                                  _CheckoutNotice(
                                    message: 'Order totals are still loading.',
                                    isDark: isDark,
                                  ),
                                ],
                                if (hasUnavailableDelivery) ...[
                                  const SizedBox(height: 10),
                                  _CheckoutNotice(
                                    message:
                                        'التوصيل غير متاح لأحد المحلات في سلتك. راجع مدينة عنوان التوصيل أو احذف المحل غير المتاح.',
                                    isDark: isDark,
                                    isBlocking: true,
                                  ),
                                ],
                                const SizedBox(height: 14),
                                _PaymentMethodCard(isDark: isDark),
                                const SizedBox(height: 14),
                                _SavedAddressCheckoutCard(
                                  address: selectedAddress,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                  ),
                  bottomNavigationBar: cartItems.isEmpty
                      ? null
                      : _CheckoutActionBar(
                          totalLabel: totalLabel,
                          pendingDeliveryTypeLabel:
                              pendingTotalDeliveryTypeLabel,
                          isDark: isDark,
                          isLoading: checkoutState is CheckoutLoading,
                          onCheckout: () {
                            if (selectedCity == null) {
                              unawaited(
                                _selectRegionForCheckoutAndRetry(context),
                              );
                              return;
                            }

                            if (selectedAddress == null) {
                              CustomSnackBar.showError(
                                context: context,
                                title: 'Shipping address required',
                                message: checkoutAddressRequiredMessage,
                              );
                              return;
                            }

                            final checkoutProblems = _checkoutRegionProblems(
                              address: selectedAddress,
                              items: cartItems,
                              selectedCity: selectedCity,
                            );
                            if (checkoutProblems.isNotEmpty) {
                              CustomSnackBar.showError(
                                context: context,
                                title: 'Cannot complete order',
                                message:
                                    'Cannot complete order because:\n\n${checkoutProblems.join('\n')}',
                              );
                              return;
                            }

                            if (hasUnavailableDelivery) {
                              CustomSnackBar.showError(
                                context: context,
                                title: 'لا يمكن إتمام الطلب',
                                message:
                                    'التوصيل غير متاح لأحد المحلات في سلتك. راجع مدينة عنوان التوصيل أو احذف المحل غير المتاح.',
                              );
                              return;
                            }

                            if (!canConfirmRemoteOrder) {
                              CustomSnackBar.showError(
                                context: context,
                                title: 'Order confirmation failed',
                                message: checkoutState.isPreviewLoading
                                    ? 'Order totals are still loading.'
                                    : 'Could not refresh order totals. Try again.',
                              );
                              context.read<CheckoutCubit>().loadPreview(
                                cartItems: cartItems,
                                useRemotePreview: !_useDemoRepositories,
                                addressId: selectedAddress.id,
                                paymentMethod: _checkoutPaymentMethod,
                                description: '',
                                deliveryNote: '',
                              );
                              return;
                            }

                            final hasMissingVariant = cartItems.any(
                              (item) =>
                                  !item.isOffer &&
                                  (item.variantId?.trim().isEmpty ?? true),
                            );
                            if (hasMissingVariant) {
                              CustomSnackBar.showError(
                                context: context,
                                title: 'Cannot complete order',
                                message:
                                    'Some cart items are missing variant information. Please add them again.',
                              );
                              return;
                            }

                            if (_useDemoRepositories) {
                              CustomSnackBar.showInfo(
                                context: context,
                                title: 'Order preview ready',
                                message: hasPreviewTotals
                                    ? 'Totals are refreshed from the backend. Order creation is not enabled in this phase.'
                                    : 'Order creation is not enabled in this phase.',
                              );
                              return;
                            }

                            context.read<CheckoutCubit>().createOrder(
                              shippingAddress: _shippingAddressFromAddress(
                                selectedAddress,
                              ),
                              items: cartItems
                                  .where((item) => !item.isOffer)
                                  .map(OrderItemData.fromCartItem)
                                  .toList(growable: false),
                              cartItems: cartItems,
                              paymentMethod: _checkoutPaymentMethod,
                              description: '',
                              deliveryNote: '',
                            );
                          },
                        ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _selectRegionForCheckoutAndRetry(BuildContext context) async {
    if (_isSelectingRegion) return;
    _isSelectingRegion = true;

    CustomSnackBar.showError(
      context: context,
      title: 'Cannot complete order',
      message: checkoutRegionRequiredMessage,
    );

    final result = await Navigator.pushNamed(
      context,
      AppRoutes.selectCity,
      arguments: const SelectCityRouteArgs(returnToCheckout: true),
    );
    if (!context.mounted) return;
    _isSelectingRegion = false;

    if (result != true) return;

    _lastPreviewKey = null;
    final cartItems = context.read<CartCubit>().state;
    final selectedCity = context.read<LocationCubit>().state.selectedCity;
    final addressState = context.read<AddressCubit>().state;
    final selectedAddress = selectedAvailableAddressForCity(
      addresses: addressState.addresses,
      selectedAddressId: addressState.selectedAddressId,
      selectedCity: selectedCity,
    );
    if (selectedAddress == null || cartItems.isEmpty) return;

    context.read<CheckoutCubit>().loadPreview(
      cartItems: cartItems,
      useRemotePreview: !_useDemoRepositories,
      addressId: selectedAddress.id,
      paymentMethod: _checkoutPaymentMethod,
      description: '',
      deliveryNote: '',
    );
  }

  PaymentSuccessRouteArgs _paymentSuccessArgs(OrderData order) {
    return PaymentSuccessRouteArgs(
      orderId: order.orderNumber.isNotEmpty ? order.orderNumber : order.id,
      status: order.statusLabel,
      reviewStatus: order.reviewStatusLabel,
      total: _formatMoney(order.total),
      marketCount: order.marketCount,
      marketSummary: order.marketNamesSummary,
      isMultiMarket: order.isMultiMarket,
      marketSections: order.marketSections
          .map((section) => section.toJson())
          .toList(growable: false),
    );
  }
}

String _notSpecifiedLabel(BuildContext context) {
  return context.tr('Not specified');
}

String _deliveryTypeLabel(BuildContext context, OrderPreviewData? preview) {
  final group = preview?.marketGroups.isEmpty ?? true
      ? null
      : preview!.marketGroups.first;
  if (group?.fulfillmentType == 'direct') {
    return context.tr('Direct delivery');
  }
  if (group?.fulfillmentType == 'external_shipping') {
    return context.tr('External shipping');
  }
  final deliveryType = group?.deliveryType ?? '';

  return switch (deliveryType) {
    'fixed_area' => context.tr('Delivery'),
    'delivery' || 'manual_quote' => context.tr('Courier'),
    _ => _notSpecifiedLabel(context),
  };
}

List<String> _checkoutRegionProblems({
  required AddressData address,
  required List<CartItemData> items,
  required CityData selectedCity,
  bool allowCustomDeliveryCity = false,
}) {
  if (allowCustomDeliveryCity) return const [];

  final deliverySlug = selectedCity.slug;
  final problems = <String>[];

  for (final item in items) {
    if (item.isAvailableForRegion(deliverySlug)) continue;

    if (item.isOffer) {
      final allowedRegion = item.regionNames.isNotEmpty
          ? item.regionNames.join(', ')
          : item.regionSlugs.join(', ');
      if (allowedRegion.trim().isNotEmpty) {
        problems.add(
          'This offer is available only in $allowedRegion and cannot be applied to the selected address.',
        );
      } else {
        problems.add(
          'This offer is not available for the selected delivery area.',
        );
      }
    } else {
      problems.add(
        'This product is not available for the selected delivery area.',
      );
    }
  }

  return problems;
}

ShippingAddressData _shippingAddressFromAddress(AddressData address) {
  return ShippingAddressData(
    id: address.id,
    fullName: address.name,
    phone: address.phoneNumber,
    line1: address.street,
    city: address.city,
    state: address.state,
    country: address.country,
    postalCode: address.postalCode,
  );
}
