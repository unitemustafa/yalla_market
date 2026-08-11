import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../domain/entities/delivery_area.dart';

const manualAreaOption = '__manual_area__';

class DeliveryAreaPickerSheet extends StatelessWidget {
  const DeliveryAreaPickerSheet({
    super.key,
    required this.areas,
    required this.selectedValue,
    required this.priceLabel,
    required this.isDark,
  });

  final List<DeliveryArea> areas;
  final String? selectedValue;
  final String Function(double? price) priceLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.62,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('Choose a delivery area'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: areas.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == areas.length) {
                      return DeliveryAreaOptionTile(
                        icon: AppIcons.edit_2,
                        title: context.tr('My area is not listed'),
                        subtitle: context.tr(
                          'Delivery price will be confirmed later',
                        ),
                        isDark: isDark,
                        isSelected: selectedValue == manualAreaOption,
                        onTap: () => Navigator.pop(context, manualAreaOption),
                      );
                    }

                    final area = areas[index];
                    final value = area.id.toString();
                    return DeliveryAreaOptionTile(
                      icon: AppIcons.location,
                      title: area.name,
                      subtitle: priceLabel(area.deliveryPrice),
                      isDark: isDark,
                      isSelected: selectedValue == value,
                      onTap: () => Navigator.pop(context, value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeliveryAreaOptionTile extends StatelessWidget {
  const DeliveryAreaOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mutedColor = addressSecondaryTextColor(context);
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08)
          : (isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFF7F8FB)),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.42)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.18 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: AppFontSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  AppIcons.tick_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AddressTextField extends StatelessWidget {
  const AddressTextField({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
    this.hintText,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textInputAction: textInputAction,
      style: const TextStyle(
        fontSize: AppFontSizes.body,
        fontWeight: FontWeight.w700,
      ),
      decoration: addressInputDecoration(
        context: context,
        icon: icon,
        label: label,
        hintText: hintText,
      ),
    );
  }
}

class AddressRetryTile extends StatelessWidget {
  const AddressRetryTile({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: Text(context.tr('Retry'))),
      ],
    );
  }
}

class DeliveryNote extends StatelessWidget {
  const DeliveryNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    return Row(
      children: [
        Icon(AppIcons.info_circle, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: AppFontSizes.label,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration addressInputDecoration({
  required BuildContext context,
  required IconData icon,
  required String label,
  String? hintText,
  String? errorText,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    prefixIcon: Icon(icon, size: 20),
    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    labelText: context.tr(label),
    labelStyle: TextStyle(
      color: addressSecondaryTextColor(context),
      fontSize: AppFontSizes.label,
      fontWeight: FontWeight.w600,
    ),
    hintText: hintText == null ? null : context.tr(hintText),
    hintStyle: TextStyle(
      color: addressSecondaryTextColor(context),
      fontSize: AppFontSizes.label,
      fontWeight: FontWeight.w600,
    ),
    errorText: errorText,
    filled: true,
    fillColor: isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF7F8FB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
      ),
    ),
  );
}

Color addressSecondaryTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
}
