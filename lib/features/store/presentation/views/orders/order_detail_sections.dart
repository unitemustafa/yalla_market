import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatters/app_currency.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../../domain/entities/order.dart';
import 'order_presentation_models.dart';

class OrderDetailRow extends StatelessWidget {
  const OrderDetailRow({
    super.key,
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

class OrderMarketSectionsSection extends StatelessWidget {
  const OrderMarketSectionsSection({
    super.key,
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
                      product: OrderProductPresentationData(
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

class OrderProductsSection extends StatelessWidget {
  const OrderProductsSection({
    super.key,
    required this.products,
    required this.itemCount,
    required this.mutedColor,
    required this.isDark,
  });

  final List<OrderProductPresentationData> products;
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

  final OrderProductPresentationData product;
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
