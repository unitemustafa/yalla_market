import 'package:flutter/material.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/network/api_result.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatters/app_currency.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../../core/presentation/widgets/app_list_entrance.dart';
import '../../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../domain/entities/order.dart';
import '../../../../../core/presentation/widgets/states/app_skeleton.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../cubit/order_history_cubit.dart';
import '../../cubit/order_history_state.dart';
import 'widgets/custom_date_range_sheet.dart';
import 'widgets/order_list_item.dart';
import 'order_details_dialog.dart';
import 'order_presentation_models.dart';
import 'orders_overview_widgets.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key, this.focusOrderId});

  final int? focusOrderId;

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView>
    with SingleTickerProviderStateMixin {
  late final AppListEntranceController _listEntrance;
  OrdersDateFilter? _dateFilter;
  DateTimeRange? _customDateRange;
  Expando<OrderPresentationData> _presentation = Expando();
  bool? _arabic;
  (List<OrderData>, ({DateTime start, DateTime end})?)? _filterInputs;
  List<OrderData> _filtered = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arabic = context.isArabicLanguage;
    if (arabic != _arabic) {
      _arabic = arabic;
      _presentation = Expando();
    }
  }

  static List<OrderData> _ordersOf(OrderHistoryState state) => switch (state) {
    OrderHistoryReady(:final orders) => orders,
    OrderHistoryFailure(:final orders) => orders,
    OrderHistoryLoading(:final orders) => orders,
    OrderHistoryInitial() => const [],
  };

  static bool _hasMore(OrderHistoryState state) =>
      state is OrderHistoryReady && state.hasMore;

  @override
  void dispose() {
    _listEntrance.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _listEntrance = AppListEntranceController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAndFocusOrder();
    });
  }

  Future<void> _loadAndFocusOrder() async {
    await context.read<OrderHistoryCubit>().loadOrders(force: true);
    if (!mounted || widget.focusOrderId == null) return;
    final state = context.read<OrderHistoryCubit>().state;
    final orders = _ordersOf(state);
    var match = orders
        .where((order) => int.tryParse(order.id) == widget.focusOrderId)
        .firstOrNull;
    if (match == null) {
      final result = await context.read<OrderHistoryCubit>().findOrder(
        widget.focusOrderId.toString(),
      );
      if (!mounted) return;
      match = result.when(
        success: (order) => order,
        failure: (failure) {
          CustomSnackBar.showError(
            context: context,
            title: 'Orders could not load',
            message: failure.message,
          );
          return null;
        },
      );
      if (result is ApiFailure) return;
    }
    if (match == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر العثور على الطلب')));
      return;
    }
    _showOrderDetails(context, _mapStoredOrder(match));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);
    return BlocConsumer<OrderHistoryCubit, OrderHistoryState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          previous.hasLoaded != current.hasLoaded ||
          previous.totalCount != current.totalCount ||
          previous.deliveredCount != current.deliveredCount ||
          _hasMore(previous) != _hasMore(current) ||
          !identical(_ordersOf(previous), _ordersOf(current)) ||
          (previous is OrderHistoryFailure &&
              current is OrderHistoryFailure &&
              previous.message != current.message),
      listener: (context, state) {
        if (state is OrderHistoryFailure &&
            (state.hasLoaded || state.orders.isNotEmpty)) {
          CustomSnackBar.showError(
            context: context,
            title: 'Refresh failed',
            message: state.message,
          );
        }
      },
      builder: (context, state) {
        final orders = _ordersOf(state);
        final filteredOrders = _filterOrders(orders);
        _listEntrance.prepare(
          filteredOrders.map((order) => order.id),
          disableAnimations: MediaQuery.disableAnimationsOf(context),
        );

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: AppRefreshIndicator(
              onRefresh: () =>
                  context.read<OrderHistoryCubit>().loadOrders(force: true),
              child:
                  (state is OrderHistoryInitial ||
                          state is OrderHistoryLoading && !state.hasLoaded) &&
                      orders.isEmpty
                  ? ListView(
                      physics: AppRefreshIndicator.scrollPhysics,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: const [
                        PageTopBar(
                          title: 'My Orders',
                          subtitle: 'Track current and previous purchases',
                        ),
                        AppRefreshAnchor(),
                        SizedBox(height: 18),
                        AppSkeletonList(rows: 4, rowHeight: 140),
                      ],
                    )
                  : state is OrderHistoryFailure &&
                        !state.hasLoaded &&
                        orders.isEmpty
                  ? ListView(
                      physics: AppRefreshIndicator.scrollPhysics,
                      padding: const EdgeInsets.all(16),
                      children: [
                        const AppRefreshAnchor(),
                        AppErrorState(
                          title: 'Orders could not load',
                          message: state.message,
                          onRetry: () => context
                              .read<OrderHistoryCubit>()
                              .loadOrders(force: true),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: AppRefreshIndicator.scrollPhysics,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      itemCount:
                          (filteredOrders.isEmpty
                              ? 4
                              : filteredOrders.length + 3) +
                          (state is OrderHistoryReady && state.hasMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (_hasMore(state) &&
                            index ==
                                (filteredOrders.isEmpty
                                    ? 4
                                    : filteredOrders.length + 3)) {
                          return const _OrdersPaginationFooter();
                        }
                        if (index == 0) {
                          return const Column(
                            children: [
                              PageTopBar(
                                title: 'My Orders',
                                subtitle:
                                    'Track current and previous purchases',
                              ),
                              AppRefreshAnchor(),
                            ],
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
                            totalCount:
                                state.totalCount ?? filteredOrders.length,
                            deliveredCount:
                                state.deliveredCount ??
                                filteredOrders
                                    .where(
                                      (order) =>
                                          order.statusLabel == 'Delivered',
                                    )
                                    .length,
                          );
                        }

                        if (filteredOrders.isEmpty) {
                          return orders.isEmpty
                              ? const OrdersEmptyState()
                              : OrdersEmptyFilterState(isDark: isDark);
                        }

                        final order = _mapStoredOrder(
                          filteredOrders[index - 3],
                        );

                        return AppListEntranceItem(
                          key: ValueKey(order.apiId),
                          controller: _listEntrance,
                          itemId: order.apiId,
                          child: OrderListItem(
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
                          ),
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
    return _presentation[order] ??= OrderPresentationData(
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
            additionNames: item.additions
                .map((addition) => addition.name)
                .toList(),
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

  List<OrderData> _filterOrders(List<OrderData> orders) {
    final range = _selectedDateRange;
    if (range == null) return orders;
    final inputs = (orders, range);
    if (_filterInputs != inputs) {
      _filterInputs = inputs;
      _filtered = orders
          .where((order) {
            final date = _dateOnly(order.placedAt);
            return !date.isBefore(range.start) && !date.isAfter(range.end);
          })
          .toList(growable: false);
    }
    return _filtered;
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
      final range = _selectedDateRange;
      await context.read<OrderHistoryCubit>().selectRange(
        range?.start,
        range?.end,
      );
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

    if (range == null || !mounted || !context.mounted) {
      return;
    }

    setState(() {
      _dateFilter = filter;
      _customDateRange = range;
    });
    if (!context.mounted) {
      return;
    }
    await context.read<OrderHistoryCubit>().selectRange(range.start, range.end);
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

class _OrdersPaginationFooter extends StatelessWidget {
  const _OrdersPaginationFooter();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<OrderHistoryCubit, OrderHistoryState, (bool, String?)>(
        selector: (state) => state is OrderHistoryReady
            ? (state.loadingMore, state.moreError)
            : (false, null),
        builder: (context, pagination) {
          final (loading, error) = pagination;
          return Column(
            children: [
              if (error != null) Text(context.tr(error)),
              TextButton(
                onPressed: loading
                    ? null
                    : context.read<OrderHistoryCubit>().loadMore,
                child: loading
                    ? const CircularProgressIndicator()
                    : Text(
                        context.tr(error == null ? 'Load more' : 'Try again'),
                      ),
              ),
            ],
          );
        },
      );
}
