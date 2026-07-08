part of 'checkout_view.dart';

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.subtotal,
    required this.deliveryTypeLabel,
    required this.discount,
    required this.shippingFeeLabel,
    required this.totalLabel,
    this.pendingTotalDeliveryTypeLabel,
    required this.isDark,
  });

  final double subtotal;
  final String deliveryTypeLabel;
  final double discount;
  final String shippingFeeLabel;
  final String totalLabel;
  final String? pendingTotalDeliveryTypeLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _IconTile(icon: AppIcons.receipt, isDark: isDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('Order Summary'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: 'Products subtotal',
            value: _formatMoney(subtotal),
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Shipping Fee',
            valueWidget: _StackedSummaryValue(
              primaryText: shippingFeeLabel,
              secondaryText: deliveryTypeLabel == _notSpecifiedLabel(context)
                  ? null
                  : deliveryTypeLabel,
              primaryColor: textColor,
              secondaryColor: AppColors.error,
            ),
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: context.tr('Discount'),
            value: _formatMoney(discount),
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Order Total'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppCurrencyText(
                        text: totalLabel,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                      if (pendingTotalDeliveryTypeLabel case final label?) ...[
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: _PendingDeliveryLine(
                            deliveryTypeLabel: label,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
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
