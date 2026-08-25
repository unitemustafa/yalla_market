import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../domain/entities/shipping_company.dart';
import 'checkout_section_card.dart';

class ShippingCompanyCard extends StatelessWidget {
  const ShippingCompanyCard({
    super.key,
    required this.companies,
    required this.selectedId,
    required this.isDark,
    required this.isLoading,
    required this.errorMessage,
    required this.onSelected,
    required this.onRetry,
  });

  final List<ShippingCompanyData> companies;
  final int? selectedId;
  final bool isDark;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<int> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CheckoutSectionCard(
      isDark: isDark,
      title: 'Shipping Company',
      icon: AppIcons.truck_fast,
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : errorMessage != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Could not load shipping companies.'),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(context.tr('Try again')),
                ),
              ],
            )
          : Column(
              children: companies
                  .map(
                    (company) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ShippingCompanyOption(
                        company: company,
                        selected: selectedId == company.id,
                        isDark: isDark,
                        onTap: () => onSelected(company.id),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _ShippingCompanyOption extends StatelessWidget {
  const _ShippingCompanyOption({
    required this.company,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final ShippingCompanyData company;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              AppImage(
                source: company.logoUrl,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.035),
                fallback: const Center(
                  child: Icon(AppIcons.truck_fast, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  company.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
