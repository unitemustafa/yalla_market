import 'package:flutter/material.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/localization/app_translations.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../../core/routing/app_route_arguments.dart';

class PaymentSuccessView extends StatelessWidget {
  const PaymentSuccessView({super.key, this.args});

  final PaymentSuccessRouteArgs? args;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBackground : Colors.white;
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final orderArgs = args;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  AppImage(
                    source: AppAssets.successfulPayment,
                    width: 270,
                    height: 270,
                    fit: BoxFit.contain,
                    cacheWidth: 540,
                    cacheHeight: 540,
                    fallback: const Icon(
                      AppIcons.clipboard_tick,
                      color: AppColors.primary,
                      size: 150,
                    ),
                  ),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: backgroundColor, width: 5),
                    ),
                    child: const Icon(
                      AppIcons.tick_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                context.tr('Order Confirmed Successfully!'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('We will contact you soon.'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedColor,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (orderArgs != null) ...[
                const SizedBox(height: 18),
                _SuccessOrderSummary(args: orderArgs, isDark: isDark),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to root/home
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    context.tr('Continue Shopping'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessOrderSummary extends StatelessWidget {
  const _SuccessOrderSummary({required this.args, required this.isDark});

  final PaymentSuccessRouteArgs args;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final mutedColor = isDark ? Colors.white70 : Colors.black54;
    final marketText = args.marketSummary.trim().isNotEmpty
        ? args.marketSummary
        : context.tr(
            '${args.marketCount} market${args.marketCount == 1 ? '' : 's'}',
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _SuccessSummaryRow(label: 'Order', value: args.orderId),
          const SizedBox(height: 8),
          _SuccessSummaryRow(label: 'Status', value: args.status),
          if (args.reviewStatus.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _SuccessSummaryRow(label: 'Review', value: args.reviewStatus),
          ],
          const SizedBox(height: 8),
          _SuccessSummaryRow(label: 'Total', value: args.total),
          if (args.isMultiMarket || args.marketCount > 1) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(AppIcons.shop, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(marketText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessSummaryRow extends StatelessWidget {
  const _SuccessSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.tr(label),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.tr(value),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
