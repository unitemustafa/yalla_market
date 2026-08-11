import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../domain/entities/cart_item.dart';
import 'cart_presentation_formatters.dart';
import 'cart_summary_widgets.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({super.key, required this.item, required this.isDark});

  final CartItemData item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _buildCartItem(context, item: item, isDark: isDark);
  }

  Widget _buildCartItem(
    BuildContext context, {
    required CartItemData item,
    required bool isDark,
  }) {
    if (item.isOffer && item.offerProducts.isNotEmpty) {
      return _buildOfferCartItem(context, item: item, isDark: isDark);
    }

    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final imageBackground = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1F3F8);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            height: 92,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: imageBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppImage(
              source: item.image,
              fallbackType: AppImagePlaceholderType.product,
              fit: BoxFit.contain,
              cacheWidth: 172,
              cacheHeight: 184,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.tr(item.brand),
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: AppFontSizes.label,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr(item.title),
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppFontSizes.bodyLarge,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.attributes.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: textColor),
                      children: _attributeSpans(context, item.attributes),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    QuantityStepper(item: item, isDark: isDark),
                    const Spacer(),
                    AppCurrencyText(
                      text: context.tr(
                        formatCartMoney(item.price * item.quantity),
                      ),
                      style: TextStyle(
                        fontSize: AppFontSizes.bodyLarge,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCartItem(
    BuildContext context, {
    required CartItemData item,
    required bool isDark,
  }) {
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final imageBackground = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1F3F8);
    final productCount = item.offerProducts.fold(
      0,
      (sum, product) => sum + product.quantity,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: imageBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppImage(
                  source: item.image,
                  fallbackType: AppImagePlaceholderType.product,
                  fit: BoxFit.contain,
                  cacheWidth: 144,
                  cacheHeight: 144,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(item.brand),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: AppFontSizes.label,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(item.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: AppFontSizes.bodyLarge,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.productCount(productCount),
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: AppFontSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 4),
          for (var index = 0; index < item.offerProducts.length; index++) ...[
            _buildOfferProductLine(
              context,
              product: item.offerProducts[index],
              isDark: isDark,
            ),
            if (index != item.offerProducts.length - 1)
              Divider(
                height: 1,
                indent: 52,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
          ],
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Text(
                context.tr('Offer price'),
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              AppCurrencyText(
                text: formatCartMoney(item.price),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: AppFontSizes.sectionTitle,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfferProductLine(
    BuildContext context, {
    required CartOfferProductData product,
    required bool isDark,
  }) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: AppImage(
              source: product.image,
              fallbackType: AppImagePlaceholderType.product,
              fit: BoxFit.contain,
              cacheWidth: 84,
              cacheHeight: 84,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(product.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (product.brand.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.tr(product.brand),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: AppFontSizes.small,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '×${product.quantity}',
            style: TextStyle(
              color: mutedColor,
              fontSize: AppFontSizes.label,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          AppCurrencyText(
            text: formatCartMoney(product.price * product.quantity),
            style: TextStyle(
              color: textColor,
              fontSize: AppFontSizes.body,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _attributeSpans(
    BuildContext context,
    List<CartItemAttribute> attributes,
  ) {
    return [
      for (final attribute in attributes) ...[
        TextSpan(
          text: '${context.tr(attribute.label)} ',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: AppFontSizes.label,
          ),
        ),
        TextSpan(
          text: '${context.tr(attribute.value)} ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppFontSizes.label,
          ),
        ),
      ],
    ];
  }
}
