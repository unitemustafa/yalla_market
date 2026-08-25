import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../domain/entities/order.dart';
import '../../cubit/order_history_cubit.dart';
import '../../cubit/order_history_state.dart';
import 'delivery_quote_approval_card.dart';
import 'order_detail_sections.dart';
import 'order_presentation_models.dart';

void showOrderDetailsDialog(
  BuildContext context,
  OrderPresentationData initialOrder, {
  required OrderPresentationData Function(OrderData order) mapStoredOrder,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final sheetColor = isDark ? const Color(0xFF222326) : Colors.white;
  final mutedColor = isDark
      ? Colors.white.withValues(alpha: 0.62)
      : Colors.black.withValues(alpha: 0.58);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
        builder: (context, state) {
          final source = switch (state) {
            OrderHistoryReady(:final orders) => orders,
            OrderHistoryFailure(:final orders) => orders,
            OrderHistoryLoading(:final orders) => orders,
            _ => const <OrderData>[],
          };
          final matches = source.where((item) => item.id == initialOrder.apiId);
          final order = matches.isEmpty
              ? initialOrder
              : mapStoredOrder(matches.first);
          return SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.86,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: mutedColor.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: order.statusColor.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            AppIcons.box,
                            color: order.statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(order.status),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: order.statusColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.orderId,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: mutedColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (order.products.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      order.marketSections.isNotEmpty
                          ? OrderMarketSectionsSection(
                              sections: order.marketSections,
                              mutedColor: mutedColor,
                              isDark: isDark,
                            )
                          : OrderProductsSection(
                              products: order.products,
                              itemCount: order.itemCount,
                              mutedColor: mutedColor,
                              isDark: isDark,
                            ),
                    ],
                    const SizedBox(height: 18),
                    if (order.isMultiMarket || order.marketCount > 1) ...[
                      OrderDetailRow(
                        icon: AppIcons.shop,
                        label: 'Markets',
                        value: order.marketSummary.trim().isNotEmpty
                            ? order.marketSummary
                            : '${order.marketCount} markets',
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order.reviewStatus.trim().isNotEmpty) ...[
                      OrderDetailRow(
                        icon: AppIcons.clipboard_tick,
                        label: 'Review',
                        value: order.reviewStatus,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 12),
                    ],
                    OrderDetailRow(
                      icon: AppIcons.money_3,
                      label: 'Payment Method',
                      value: order.paymentMethod,
                      mutedColor: mutedColor,
                    ),
                    if (order.shippingCompany.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      OrderDetailRow(
                        icon: AppIcons.truck_fast,
                        label: 'Shipping Company',
                        value: order.shippingCompany,
                        mutedColor: mutedColor,
                      ),
                    ],
                    const SizedBox(height: 12),
                    OrderDetailRow(
                      icon: AppIcons.truck_fast,
                      label: 'Delivery type',
                      value: order.deliveryType,
                      mutedColor: mutedColor,
                    ),
                    if (order.deliveryPriceStatus ==
                        OrderDeliveryPriceStatus.awaitingCustomerApproval) ...[
                      const SizedBox(height: 14),
                      DeliveryQuoteApprovalCard(
                        orderId: order.apiId,
                        deliveryPrice: order.deliveryPrice,
                        total: order.total,
                        isDark: isDark,
                      ),
                    ],
                    const SizedBox(height: 12),
                    OrderDetailRow(
                      icon: AppIcons.calendar,
                      label: 'Order date',
                      value: order.date,
                      mutedColor: mutedColor,
                    ),
                    const SizedBox(height: 12),
                    OrderDetailRow(
                      icon: AppIcons.calendar_1,
                      label: 'Shipping date',
                      value: order.shippingDate,
                      mutedColor: mutedColor,
                    ),
                    const SizedBox(height: 12),
                    OrderDetailRow(
                      icon: AppIcons.shopping_bag,
                      label: 'Items',
                      value: context.productCount(order.itemCount),
                      mutedColor: mutedColor,
                    ),
                    const SizedBox(height: 12),
                    OrderDetailRow(
                      icon: AppIcons.receipt_text,
                      label: 'Total',
                      value: order.total,
                      mutedColor: mutedColor,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          AppIcons.tick_circle,
                          color: Colors.white,
                        ),
                        label: Text(
                          context.tr('Done'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
