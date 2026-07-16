part of 'orders_view.dart';

class _OrdersSummaryCard extends StatelessWidget {
  const _OrdersSummaryCard({required this.isDark, required this.orders});

  final bool isDark;
  final List<_OrderData> orders;

  @override
  Widget build(BuildContext context) {
    final deliveredCount = orders
        .where((order) => order.status == 'Delivered')
        .length;
    final activeCount = orders.length - deliveredCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25273A) : const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          _SummaryPill(
            icon: AppIcons.receipt_text,
            value: '${orders.length}',
            label: 'Total',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _SummaryPill(
            icon: AppIcons.truck_fast,
            value: '$activeCount',
            label: 'Shipment on the way',
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          _SummaryPill(
            icon: AppIcons.tick_circle,
            value: '$deliveredCount',
            label: 'Delivered',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _OrdersDateFilterBar extends StatelessWidget {
  const _OrdersDateFilterBar({
    required this.selected,
    required this.customRange,
    required this.onChanged,
  });

  final _OrdersDateFilter? selected;
  final DateTimeRange? customRange;
  final ValueChanged<_OrdersDateFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = [
      (_OrdersDateFilter.today, 'Today'),
      (_OrdersDateFilter.week, 'This week'),
      (_OrdersDateFilter.month, 'This month'),
      (_OrdersDateFilter.custom, _customLabel(context)),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selected == option.$1;
          final foregroundColor = isSelected
              ? Colors.white
              : isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextPrimary;

          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(
              context.tr(option.$2),
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            avatar: option.$1 == _OrdersDateFilter.custom
                ? Icon(AppIcons.calendar, size: 16, color: foregroundColor)
                : null,
            selectedColor: AppColors.primary,
            backgroundColor: isDark ? AppColors.darkCardColor : Colors.white,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (_) => onChanged(option.$1),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: options.length,
      ),
    );
  }

  String _customLabel(BuildContext context) {
    final range = customRange;
    if (selected != _OrdersDateFilter.custom || range == null) {
      return 'Custom';
    }

    return '${_shortDate(range.start)} - ${_shortDate(range.end)}';
  }

  String _shortDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}';
  }
}

class _OrdersEmptyFilterState extends StatelessWidget {
  const _OrdersEmptyFilterState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(AppIcons.calendar, color: mutedColor, size: 28),
          const SizedBox(height: 10),
          Text(
            context.tr('No orders in this period'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: AppEmptyState(
        title: 'No orders yet',
        message: 'Your orders will appear here once you place an order.',
        icon: AppIcons.receipt_text,
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.black.withValues(alpha: 0.52);

    return Expanded(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCurrencyText(
                  text: context.tr(value),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  context.tr(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.mutedColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: mutedColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.tr(label),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        AppCurrencyText(
          text: context.tr(value),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _OrderMarketSectionsSection extends StatelessWidget {
  const _OrderMarketSectionsSection({
    required this.sections,
    required this.mutedColor,
    required this.isDark,
  });

  final List<OrderMarketSectionData> sections;
  final Color mutedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.shop, size: 18, color: mutedColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('Market sections'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final section in sections) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        section.marketName.trim().isEmpty
                            ? context.tr('Market')
                            : section.marketName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (section.subtotal > 0)
                      AppCurrencyText(
                        text: AppCurrency.format(
                          section.subtotal,
                          fractionDigits: 2,
                          trimTrailingZero: false,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
                if (section.pickupStatus.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.tr(section.pickupStatusLabel),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (section.items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final item in section.items) ...[
                    _OrderProductRow(
                      product: _OrderProductData(
                        title: item.title.trim().isEmpty ? 'Item' : item.title,
                        brand: item.brand,
                        quantity: item.quantity,
                        total: AppCurrency.format(
                          item.lineTotal,
                          fractionDigits: 2,
                          trimTrailingZero: false,
                        ),
                      ),
                      mutedColor: mutedColor,
                    ),
                    if (item != section.items.last)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: borderColor),
                      ),
                  ],
                ],
                if (section.offers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    context.tr('${section.offers.length} offers'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (section != sections.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OrderProductsSection extends StatelessWidget {
  const _OrderProductsSection({
    required this.products,
    required this.itemCount,
    required this.mutedColor,
    required this.isDark,
  });

  final List<_OrderProductData> products;
  final int itemCount;
  final Color mutedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(AppIcons.shopping_bag, size: 18, color: mutedColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('Products'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                context.productCount(itemCount),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final product in products) ...[
            _OrderProductRow(product: product, mutedColor: mutedColor),
            if (product != products.last)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: borderColor),
              ),
          ],
        ],
      ),
    );
  }
}

class _OrderProductRow extends StatelessWidget {
  const _OrderProductRow({required this.product, required this.mutedColor});

  final _OrderProductData product;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final brand = product.brand.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 32),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'x${product.quantity}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(product.title),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (brand.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  context.tr(brand),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (product.total != null) ...[
          const SizedBox(width: 10),
          AppCurrencyText(
            text: product.total!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ],
    );
  }
}

class _OrderData {
  const _OrderData({
    required this.apiId,
    required this.status,
    required this.placedAt,
    required this.date,
    required this.orderId,
    required this.shippingDate,
    required this.itemCount,
    required this.total,
    required this.products,
    this.reviewStatus = '',
    this.paymentMethod = '',
    this.deliveryType = '',
    this.isMultiMarket = false,
    this.marketCount = 1,
    this.marketSummary = '',
    this.marketSections = const [],
  });

  final String apiId;
  final String status;
  final DateTime placedAt;
  final String date;
  final String orderId;
  final String shippingDate;
  final int itemCount;
  final String total;
  final List<_OrderProductData> products;
  final String reviewStatus;
  final String paymentMethod;
  final String deliveryType;
  final bool isMultiMarket;
  final int marketCount;
  final String marketSummary;
  final List<OrderMarketSectionData> marketSections;

  factory _OrderData.fromDemo(DemoOrderData order) {
    final status = order.status == 'Delivered'
        ? 'Delivered'
        : 'Shipment on the way';

    return _OrderData(
      apiId: order.orderId,
      status: status,
      placedAt: _parseDemoOrderDate(order.date),
      date: order.date,
      orderId: order.orderId,
      shippingDate: order.shippingDate,
      itemCount: order.itemCount,
      total: order.total,
      products: order.items
          .map(
            (item) => _OrderProductData(
              title: item.title,
              brand: item.brand,
              quantity: item.quantity,
              total: item.total,
            ),
          )
          .toList(growable: false),
      paymentMethod: 'Cash on Delivery',
      deliveryType: 'Delivery',
    );
  }

  Color get statusColor {
    return status == 'Delivered' ? AppColors.success : AppColors.warning;
  }
}

DateTime _parseDemoOrderDate(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return DateTime.now();

  final day = int.tryParse(parts[0]) ?? DateTime.now().day;
  final year = int.tryParse(parts[2]) ?? DateTime.now().year;
  final month =
      const {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      }[parts[1]] ??
      DateTime.now().month;

  return DateTime(year, month, day);
}

class _OrderProductData {
  const _OrderProductData({
    required this.title,
    required this.quantity,
    this.brand = '',
    this.total,
  });

  final String title;
  final int quantity;
  final String brand;
  final String? total;
}
