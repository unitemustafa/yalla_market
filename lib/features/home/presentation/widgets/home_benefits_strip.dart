import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_translations.dart';

class HomeBenefitsStrip extends StatelessWidget {
  const HomeBenefitsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : AppColors.primary.withValues(alpha: 0.10);

    return Container(
      key: const ValueKey('home_benefits_strip'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BenefitItem(
              key: const ValueKey('home_benefit_delivery'),
              icon: AppIcons.truck_fast,
              prefix: context.tr('Delivery within'),
              emphasis: '30',
              suffix: context.tr('minutes'),
            ),
          ),
          _BenefitDivider(color: dividerColor),
          Expanded(
            child: _BenefitItem(
              key: const ValueKey('home_benefit_discount'),
              icon: AppIcons.verify5,
              prefix: context.tr('Discounts up to'),
              emphasis: '45%',
            ),
          ),
          _BenefitDivider(color: dividerColor),
          Expanded(
            child: _BenefitItem(
              key: const ValueKey('home_benefit_payment'),
              icon: AppIcons.card_tick,
              label: context.tr('Pay cash'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitDivider extends StatelessWidget {
  const _BenefitDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: color,
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    super.key,
    required this.icon,
    this.label,
    this.prefix,
    this.emphasis,
    this.suffix,
  });

  final IconData icon;
  final String? label;
  final String? prefix;
  final String? emphasis;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final baseStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: textColor,
      fontSize: AppFontSizes.micro,
      height: 1.25,
      fontWeight: FontWeight.w700,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 3),
          label != null
              ? Text(
                  label!,
                  style: baseStyle,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                )
              : Text.rich(
                  TextSpan(
                    style: baseStyle,
                    children: [
                      TextSpan(text: '${prefix ?? ''} '),
                      TextSpan(
                        text: emphasis,
                        style: baseStyle?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (suffix?.isNotEmpty == true)
                        TextSpan(text: ' $suffix'),
                    ],
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }
}
