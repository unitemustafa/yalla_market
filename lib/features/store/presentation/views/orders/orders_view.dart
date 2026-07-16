import 'package:flutter/material.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../../core/config/app_environment.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatters/app_currency.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../../data/demo/demo_orders.dart';
import '../../../domain/entities/order.dart';
import '../../cubit/order_history_cubit.dart';
import '../../cubit/order_history_state.dart';
import 'widgets/custom_date_range_sheet.dart';
import 'widgets/order_list_item.dart';

part 'orders_widgets_part.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key, this.useDemoOrders, this.focusOrderId});

  final bool? useDemoOrders;
  final int? focusOrderId;

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

enum _OrdersDateFilter { today, week, month, custom }

class _OrdersViewState extends State<OrdersView> {
  static final List<_OrderData> _orders = DemoOrders.all
      .map(_OrderData.fromDemo)
      .toList(growable: false);

  _OrdersDateFilter? _dateFilter;
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
    final useDemoOrders =
        widget.useDemoOrders ?? AppEnvironment.useDemoRepositories;

    return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
      builder: (context, state) {
        final loadedOrders = state is OrderHistoryReady
            ? state.orders.map(_mapStoredOrder).toList(growable: false)
            : state is OrderHistoryFailure
            ? state.orders.map(_mapStoredOrder).toList(growable: false)
            : const <_OrderData>[];
        final orders = loadedOrders.isEmpty && useDemoOrders
            ? _orders
            : loadedOrders;
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
                          return _OrdersDateFilterBar(
                            selected: _dateFilter,
                            customRange: _customDateRange,
                            onChanged: (filter) =>
                                _selectDateFilter(context, filter),
                          );
                        }

                        if (index == 2) {
                          return _OrdersSummaryCard(
                            isDark: isDark,
                            orders: filteredOrders,
                          );
                        }

                        if (filteredOrders.isEmpty) {
                          return orders.isEmpty
                              ? const _OrdersEmptyState()
                              : _OrdersEmptyFilterState(isDark: isDark);
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

  _OrderData _mapStoredOrder(OrderData order) {
    return _OrderData(
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
      deliveryType: order.deliveryTypeLabel,
      isMultiMarket: order.isMultiMarket,
      marketCount: order.marketCount,
      marketSummary: order.marketNamesSummary,
      marketSections: order.marketSections,
    );
  }

  List<_OrderProductData> _productsFromOrder(OrderData order) {
    final sectionItems = order.marketSections
        .expand((section) => section.items)
        .toList(growable: false);
    final source = sectionItems.isEmpty ? order.items : sectionItems;
    return source
        .map(
          (item) => _OrderProductData(
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

  List<_OrderData> _filterOrders(List<_OrderData> orders) {
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
      _OrdersDateFilter.today => (start: now, end: now),
      _OrdersDateFilter.week => (
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
      _OrdersDateFilter.month => (
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      _OrdersDateFilter.custom =>
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
    _OrdersDateFilter filter,
  ) async {
    if (filter != _OrdersDateFilter.custom) {
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

  void _showOrderDetails(BuildContext context, _OrderData initialOrder) {
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
            final matches = source.where(
              (item) => item.id == initialOrder.apiId,
            );
            final order = matches.isEmpty
                ? initialOrder
                : _mapStoredOrder(matches.first);
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
                            ? _OrderMarketSectionsSection(
                                sections: order.marketSections,
                                mutedColor: mutedColor,
                                isDark: isDark,
                              )
                            : _OrderProductsSection(
                                products: order.products,
                                itemCount: order.itemCount,
                                mutedColor: mutedColor,
                                isDark: isDark,
                              ),
                      ],
                      const SizedBox(height: 18),
                      if (order.isMultiMarket || order.marketCount > 1) ...[
                        _DetailRow(
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
                        _DetailRow(
                          icon: AppIcons.clipboard_tick,
                          label: 'Review',
                          value: order.reviewStatus,
                          mutedColor: mutedColor,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _DetailRow(
                        icon: AppIcons.money_3,
                        label: 'Payment Method',
                        value: order.paymentMethod,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: AppIcons.truck_fast,
                        label: 'Delivery type',
                        value: order.deliveryType,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: AppIcons.calendar,
                        label: 'Order date',
                        value: order.date,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: AppIcons.calendar_1,
                        label: 'Shipping date',
                        value: order.shippingDate,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: AppIcons.shopping_bag,
                        label: 'Items',
                        value: context.productCount(order.itemCount),
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
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
}
