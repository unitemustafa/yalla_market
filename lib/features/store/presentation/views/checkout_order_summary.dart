part of 'checkout_view.dart';

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.subtotal,
    required this.deliveryTypeLabel,
    required this.discount,
    required this.discountLabel,
    required this.shippingFeeLabel,
    required this.totalLabel,
    required this.isDark,
  });

  final double subtotal;
  final String deliveryTypeLabel;
  final double discount;
  final String discountLabel;
  final String shippingFeeLabel;
  final String totalLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isShippingFeeUnspecified =
        shippingFeeLabel == _notSpecifiedLabel(context);
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
            valueWidget: _InlineSummaryValue(
              primaryText: shippingFeeLabel,
              secondaryText:
                  isShippingFeeUnspecified ||
                      deliveryTypeLabel == _notSpecifiedLabel(context)
                  ? null
                  : deliveryTypeLabel,
              primaryColor: isShippingFeeUnspecified
                  ? AppColors.error
                  : textColor,
              secondaryColor: AppColors.error,
            ),
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: discountLabel,
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
            key: const ValueKey('order-total-panel'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    key: const ValueKey('order-total-label'),
                    context.tr('Order Total'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: AppFontSizes.bodyLarge,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Column(
                      key: const ValueKey('order-total-value'),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppCurrencyText(
                          text: totalLabel,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: AppFontSizes.subtitle,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ],
                    ),
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

String _discountSummaryLabel(BuildContext context, OrderPreviewData? preview) {
  if (preview == null) return context.tr('Discount');

  final percentages = <double>{};
  var hasOffer = false;
  for (final group in preview.marketGroups) {
    for (final offer in group.selectedOffers) {
      hasOffer = true;
      final percentage = _previewDouble(offer['discount_percentage']);
      if (percentage != null && percentage > 0) percentages.add(percentage);
    }
  }

  if (!hasOffer) return context.tr('Discount');
  final baseLabel = context.tr('Offer discount');
  if (percentages.length != 1) return baseLabel;

  final percentage = percentages.single;
  final percentageLabel = percentage == percentage.roundToDouble()
      ? percentage.toInt().toString()
      : percentage.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return '$baseLabel ($percentageLabel%)';
}
