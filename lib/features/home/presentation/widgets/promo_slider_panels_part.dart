part of 'promo_slider.dart';

class _OfferSummaryPanel extends StatelessWidget {
  const _OfferSummaryPanel({
    required this.offer,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  final _PromoOfferData offer;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _OfferPanel(
      isDark: isDark,
      child: Column(
        children: [
          _PanelTitle(
            icon: AppIcons.receipt,
            title: context.tr('Order Summary'),
            textColor: textColor,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          if (offer.discountRate(context) != null) ...[
            _SummaryLine(
              label: context.isArabicLanguage ? 'نسبة الخصم' : 'Discount rate',
              value: offer.discountRate(context)!,
              valueColor: offer.color,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 10),
          ],
          _SummaryLine(
            label: context.isArabicLanguage
                ? 'السعر قبل الخصم'
                : 'Before discount',
            value: offer.subtotal,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: context.isArabicLanguage ? 'قيمة الخصم' : 'Discount value',
            value: '- ${offer.discount}',
            valueColor: AppColors.success,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: context.isArabicLanguage
                ? 'السعر بعد الخصم'
                : 'After discount',
            value: offer.afterDiscount,
            valueColor: offer.color,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: context.isArabicLanguage ? 'التوصيل' : 'Delivery',
            value: offer.deliveryFee,
            valueColor: AppColors.success,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Order Total'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                AppCurrencyText(
                  text: offer.total,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
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

class _OfferPaymentPanel extends StatelessWidget {
  const _OfferPaymentPanel({
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _OfferPanel(
      isDark: isDark,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(AppIcons.money_3, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Cash on Delivery'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('Pay when your order arrives'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(AppIcons.tick_circle, color: AppColors.primary, size: 19),
        ],
      ),
    );
  }
}

class _OfferCheckoutBar extends StatelessWidget {
  const _OfferCheckoutBar({
    required this.offer,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
    required this.onCheckout,
  });

  final _PromoOfferData offer;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.productCount(offer.products.length),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AppCurrencyText(
                    text: offer.total,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontSize: AppFontSizes.title,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCheckout,
                icon: const Icon(AppIcons.card_tick, size: 19),
                label: Text(context.tr('Checkout')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.textColor,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final Color textColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    required this.textColor,
    required this.mutedColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color mutedColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? textColor;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppCurrencyText(
              text: value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
              currencyColor: AppColors.currency,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.text,
    required this.color,
    required this.isDark,
  });

  final String text;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OfferPanel extends StatelessWidget {
  const _OfferPanel({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: child,
    );
  }
}
