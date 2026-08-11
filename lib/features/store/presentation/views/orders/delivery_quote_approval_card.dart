import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../cubit/order_history_cubit.dart';

class DeliveryQuoteApprovalCard extends StatefulWidget {
  const DeliveryQuoteApprovalCard({
    super.key,
    required this.orderId,
    required this.deliveryPrice,
    required this.total,
    required this.isDark,
  });

  final String orderId;
  final String deliveryPrice;
  final String total;
  final bool isDark;

  @override
  State<DeliveryQuoteApprovalCard> createState() =>
      _DeliveryQuoteApprovalCardState();
}

class _DeliveryQuoteApprovalCardState extends State<DeliveryQuoteApprovalCard> {
  bool _submitting = false;

  Future<void> _approve() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final error = await context.read<OrderHistoryCubit>().acceptDeliveryQuote(
      widget.orderId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            error == null
                ? 'Delivery price approved'
                : 'Could not approve delivery price',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.primary.withValues(alpha: 0.24);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: widget.isDark ? 0.13 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Delivery price approval'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              'The delivery price was set by the administration. Review it before approving.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _QuoteAmountRow(
            label: context.tr('Delivery price'),
            value: widget.deliveryPrice,
          ),
          const SizedBox(height: 6),
          _QuoteAmountRow(
            label: context.tr('Order total'),
            value: widget.total,
            strong: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _approve,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(AppIcons.tick_circle, color: Colors.white),
              label: Text(
                context.tr('Approve delivery price'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteAmountRow extends StatelessWidget {
  const _QuoteAmountRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        AppCurrencyText(
          text: value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
