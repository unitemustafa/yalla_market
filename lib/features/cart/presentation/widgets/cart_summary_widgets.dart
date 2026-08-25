import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../domain/entities/cart_item.dart';
import '../cubit/cart_cubit.dart';
import 'cart_presentation_formatters.dart';

class CartCountBadge extends StatelessWidget {
  const CartCountBadge({super.key, required this.count, required this.isDark});

  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.shopping_bag, color: AppColors.primary, size: 17),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSizes.body,
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.item, required this.isDark});

  final CartItemData item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _QuantityButton(
            icon: AppIcons.minus,
            color: item.quantity > 1
                ? (isDark ? Colors.white70 : Colors.black54)
                : (isDark ? Colors.white30 : Colors.black26),
            onTap: () {
              if (item.quantity > 1) {
                context.read<CartCubit>().decrementQuantity(item.id);
              } else {
                CustomSnackBar.showWarning(
                  context: context,
                  title: 'Minimum quantity is 1',
                );
              }
            },
          ),
          SizedBox(
            width: 36,
            child: Text(
              item.quantity.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSizes.bodyLarge,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ),
          _QuantityButton(
            icon: AppIcons.add,
            color: Colors.white,
            backgroundColor: AppColors.primary,
            onTap: () => context.read<CartCubit>().incrementQuantity(item.id),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class CheckoutSummary extends StatelessWidget {
  const CheckoutSummary({
    super.key,
    required this.subtotal,
    required this.itemCount,
    required this.isDark,
    required this.onCheckout,
  });

  final double subtotal;
  final int itemCount;
  final bool isDark;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final total = subtotal;
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SummaryRow(
                    label: 'Subtotal',
                    value: formatCartMoney(subtotal),
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Delivery',
                    value: cartNotSpecifiedLabel(context),
                    textColor: textColor,
                    mutedColor: mutedColor,
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.productCount(itemCount),
                              style: TextStyle(
                                color: mutedColor,
                                fontSize: AppFontSizes.label,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            AppCurrencyText(
                              text: context.tr(formatCartMoney(total)),
                              style: TextStyle(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
    return Row(
      children: [
        Text(
          context.tr(label),
          style: TextStyle(
            color: mutedColor,
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        AppCurrencyText(
          text: context.tr(value),
          style: TextStyle(
            color: valueColor ?? textColor,
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class EmptyCartView extends StatelessWidget {
  const EmptyCartView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      title: 'Your cart is empty',
      message: 'Add products you like and review them here before checkout.',
      icon: AppIcons.shopping_bag,
    );
  }
}
