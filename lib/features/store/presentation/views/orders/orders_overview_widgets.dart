import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../../core/presentation/widgets/texts/app_currency_text.dart';
import 'order_presentation_models.dart';

class OrdersSummaryCard extends StatelessWidget {
  const OrdersSummaryCard({
    super.key,
    required this.isDark,
    required this.orders,
  });

  final bool isDark;
  final List<OrderPresentationData> orders;

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

class OrdersDateFilterBar extends StatelessWidget {
  const OrdersDateFilterBar({
    super.key,
    required this.selected,
    required this.customRange,
    required this.onChanged,
  });

  final OrdersDateFilter? selected;
  final DateTimeRange? customRange;
  final ValueChanged<OrdersDateFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = [
      (OrdersDateFilter.today, 'Today'),
      (OrdersDateFilter.week, 'This week'),
      (OrdersDateFilter.month, 'This month'),
      (OrdersDateFilter.custom, _customLabel(context)),
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
            avatar: option.$1 == OrdersDateFilter.custom
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
    if (selected != OrdersDateFilter.custom || range == null) {
      return 'Custom';
    }

    return '${_shortDate(range.start)} - ${_shortDate(range.end)}';
  }

  String _shortDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}';
  }
}

class OrdersEmptyFilterState extends StatelessWidget {
  const OrdersEmptyFilterState({super.key, required this.isDark});

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

class OrdersEmptyState extends StatelessWidget {
  const OrdersEmptyState({super.key});

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
