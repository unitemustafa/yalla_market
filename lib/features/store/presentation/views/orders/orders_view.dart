import 'package:flutter/material.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatters/app_currency.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../domain/entities/order.dart';
import '../../cubit/order_history_cubit.dart';
import '../../cubit/order_history_state.dart';
import 'widgets/custom_date_range_sheet.dart';
import 'widgets/order_list_item.dart';
import 'order_details_dialog.dart';
import 'order_presentation_models.dart';
import 'orders_overview_widgets.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key, this.useDemoOrders, this.focusOrderId});

  final bool? useDemoOrders;
  final int? focusOrderId;

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  OrdersDateFilter? _dateFilter;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAndFocusOrder();
    });
  }

  Future<void> _loadAndFocusOrder() async {
    await context.read<OrderHistoryCubit>().loadOrders(force: true);
    if (!mounted || widget.focusOrderId == null) return;
    final state = context.read<OrderHistoryCubit>().state;
    final orders = switch (state) {
      OrderHistoryReady(:final orders) => orders,
      OrderHistoryFailure(:final orders) => orders,
      OrderHistoryLoading(:final orders) => orders,
      _ => const <OrderData>[],
    };
    final match = orders.where(
      (order) => int.tryParse(order.id) == widget.focusOrderId,
    );
    if (match.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر العثور على الطلب')));
      return;
    }
    _showOrderDetails(context, _mapStoredOrder(match.first));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);
    return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
      builder: (context, state) {
        final loadedOrders = state is OrderHistoryReady
            ? state.orders.map(_mapStoredOrder).toList(growable: false)
            : state is OrderHistoryFailure
            ? state.orders.map(_mapStoredOrder).toList(growable: false)
            : const <OrderPresentationData>[];
        final orders = loadedOrders;
        final filteredOrders = _filterOrders(orders);

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: state is OrderHistoryLoading
                ? const AppLoadingState(message: 'Loading orders...')
                : state is OrderHistoryFailure && loadedOrders.isEmpty
                ? AppErrorState(
                    title: 'Orders could not load',
                    message: state.message,
                    onRetry: () => context.read<OrderHistoryCubit>().loadOrders(
                      force: true,
                    ),
                  )
                : AppRefreshIndicator(
                    onRefresh: () => context
                        .read<OrderHistoryCubit>()
                        .loadOrders(force: true),
                    child: ListView.separated(
                      physics: AppRefreshIndicator.scrollPhysics,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      itemCount: filteredOrders.isEmpty
                          ? 4
                          : filteredOrders.length + 3,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const PageTopBar(
                            title: 'My Orders',
                            subtitle: 'Track current and previous purchases',
                          );
                        }

                        if (index == 1) {
                          return OrdersDateFilterBar(
                            selected: _dateFilter,
                            customRange: _customDateRange,
                            onChanged: (filter) =>
                                _selectDateFilter(context, filter),
                          );
                        }

                        if (index == 2) {
                          return OrdersSummaryCard(
                            isDark: isDark,
                            orders: filteredOrders,
                          );
                        }

                        if (filteredOrders.isEmpty) {
                          return orders.isEmpty
                              ? const OrdersEmptyState()
                              : OrdersEmptyFilterState(isDark: isDark);
                        }

                        final order = filteredOrders[index - 3];

                        return OrderListItem(
                          status: order.status,
                          date: order.date,
                          orderId: order.orderId,
                          shippingDate: order.shippingDate,
                          itemCount: order.itemCount,
                          total: order.total,
                          statusColor: order.statusColor,
                          products: order.products
                              .map(
                                (product) => OrderListItemProduct(
                                  title: product.title,
                                  brand: product.brand,
                                  quantity: product.quantity,
                                ),
                              )
                              .toList(growable: false),
                          isMultiMarket: order.isMultiMarket,
                          marketCount: order.marketCount,
                          marketSummary: order.marketSummary,
                          onTap: () => _showOrderDetails(context, order),
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }

  OrderPresentationData _mapStoredOrder(OrderData order) {
    return OrderPresentationData(
      apiId: order.id,
      status: order.statusLabel,
      placedAt: order.placedAt,
      date: _formatDate(order.placedAt),
      orderId: order.orderNumber,
      shippingDate: _formatDate(order.estimatedDeliveryAt),
      itemCount: order.itemCount,
      total: _formatMoney(order.total),
      products: _productsFromOrder(order),
      reviewStatus: order.reviewStatusLabel,
      paymentMethod: order.paymentMethodLabel,
      shippingCompany: order.shippingCompany?.name ?? '',
      deliveryType: order.deliveryTypeLabel,
      deliveryPriceStatus: order.deliveryPriceStatus,
      deliveryPrice: _formatMoney(order.shippingFee),
      isMultiMarket: order.isMultiMarket,
      marketCount: order.marketCount,
      marketSummary: order.marketNamesSummary,
      marketSections: order.marketSections,
      multiMarketFeeRate: order.multiMarketFeeRate,
      multiMarketFee: order.multiMarketFee,
    );
  }

  List<OrderProductPresentationData> _productsFromOrder(OrderData order) {
    final sectionItems = order.marketSections
        .expand((section) => section.items)
        .toList(growable: false);
    final source = sectionItems.isEmpty ? order.items : sectionItems;
    return source
        .map(
          (item) => OrderProductPresentationData(
            title: item.title.trim().isEmpty ? 'Item' : item.title,
            brand: item.brand,
            quantity: item.quantity,
            total: _formatMoney(item.lineTotal),
          ),
        )
        .toList(growable: false);
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')} '
        '${_monthName(value.month)} ${value.year}';
  }

  List<OrderPresentationData> _filterOrders(
    List<OrderPresentationData> orders,
  ) {
    final range = _selectedDateRange;
    if (range == null) return orders;

    return orders
        .where((order) {
          final date = _dateOnly(order.placedAt);
          return !date.isBefore(range.start) && !date.isAfter(range.end);
        })
        .toList(growable: false);
  }

  ({DateTime start, DateTime end})? get _selectedDateRange {
    final now = _dateOnly(DateTime.now());

    return switch (_dateFilter) {
      null => null,
      OrdersDateFilter.today => (start: now, end: now),
      OrdersDateFilter.week => (
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
      OrdersDateFilter.month => (
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      OrdersDateFilter.custom =>
        _customDateRange == null
            ? null
            : (
                start: _dateOnly(_customDateRange!.start),
                end: _dateOnly(_customDateRange!.end),
              ),
    };
  }

  Future<void> _selectDateFilter(
    BuildContext context,
    OrdersDateFilter filter,
  ) async {
    if (filter != OrdersDateFilter.custom) {
      setState(() => _dateFilter = filter);
      return;
    }

    final now = _dateOnly(DateTime.now());
    final range = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomDateRangeSheet(
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 1, 12, 31),
        initialRange:
            _customDateRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      ),
    );

    if (range == null) return;

    setState(() {
      _dateFilter = filter;
      _customDateRange = range;
    });
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatMoney(double value) =>
      AppCurrency.format(value, fractionDigits: 2, trimTrailingZero: false);

  String _monthName(int month) {
    const englishNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const arabicNames = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final names = context.isArabicLanguage ? arabicNames : englishNames;
    return names[(month - 1).clamp(0, names.length - 1)];
  }

  void _showOrderDetails(BuildContext context, OrderPresentationData order) {
    showOrderDetailsDialog(context, order, mapStoredOrder: _mapStoredOrder);
  }
}
