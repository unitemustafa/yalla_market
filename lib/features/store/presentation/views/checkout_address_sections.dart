import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../location/domain/entities/city_data.dart';
import '../../../personalization/domain/entities/address.dart';
import 'checkout_city_picker.dart';
import 'checkout_input_decoration.dart';
import 'checkout_section_card.dart';

class SavedAddressCheckoutCard extends StatelessWidget {
  const SavedAddressCheckoutCard({
    super.key,
    required this.address,
    required this.isDark,
  });

  final AddressData? address;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final hasAddress = address != null;

    return CheckoutSectionCard(
      isDark: isDark,
      title: 'Shipping Address',
      icon: AppIcons.location,
      actionLabel: hasAddress ? 'Change' : 'Add',
      onAction: () => Navigator.pushNamed(
        context,
        AppRoutes.addresses,
        arguments: const AddressesRouteArgs(returnAfterSelection: true),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasAddress ? AppIcons.location : AppIcons.location_add,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAddress
                      ? address!.name
                      : context.tr('Choose a saved address'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  hasAddress
                      ? address!.fullAddress
                      : context.tr('Add an address to start checkout faster.'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: AppFontSizes.label,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

// ignore: unused_element
class _ShippingAddressCard extends StatelessWidget {
  const _ShippingAddressCard({
    required this.isDark,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.streetController,
    required this.manualCityController,
    required this.selectedCity,
    required this.isManualCity,
    required this.isExpanded,
    required this.requiredValidator,
    required this.phoneValidator,
    required this.cityValidator,
    required this.onToggleExpanded,
    required this.onCityChanged,
  });

  final bool isDark;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController streetController;
  final TextEditingController manualCityController;
  final CityData? selectedCity;
  final bool isManualCity;
  final bool isExpanded;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> phoneValidator;
  final FormFieldValidator<String> cityValidator;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String?> onCityChanged;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final cityValue = isManualCity ? manualCityOption : selectedCity?.slug;

    return CheckoutSectionCard(
      isDark: isDark,
      title: 'Shipping Address',
      icon: AppIcons.location,
      trailing: IconButton(
        onPressed: onToggleExpanded,
        icon: RotatedBox(
          quarterTurns: isExpanded ? 2 : 0,
          child: Icon(AppIcons.arrow_down_1, color: mutedColor, size: 20),
        ),
        tooltip: isExpanded ? 'Collapse' : 'Expand',
      ),
      child: AnimatedCrossFade(
        firstChild: _CollapsedAddressSummary(
          isDark: isDark,
          name: nameController.text.trim(),
          city: isManualCity
              ? manualCityController.text.trim()
              : selectedCity?.displayName(arabic: context.isArabicLanguage) ??
                    '',
        ),
        secondChild: Form(
          key: formKey,
          child: Column(
            children: [
              _CheckoutAddressTextField(
                controller: nameController,
                icon: AppIcons.user,
                label: 'Name',
                validator: requiredValidator,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _CheckoutAddressTextField(
                controller: phoneController,
                icon: AppIcons.mobile,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: phoneValidator,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              FormField<String>(
                key: ValueKey(cityValue),
                initialValue: cityValue,
                validator: cityValidator,
                builder: (field) {
                  final selectedText = isManualCity
                      ? (context.isArabicLanguage
                            ? 'إدخال يدوي'
                            : 'Manual entry')
                      : selectedCity?.displayName(
                              arabic: context.isArabicLanguage,
                            ) ??
                            '';

                  return InkWell(
                    onTap: () async {
                      final picked = await openCityPicker(
                        context: context,
                        isDark: isDark,
                        selectedValue: cityValue,
                      );
                      if (picked == null) return;
                      field.didChange(picked);
                      onCityChanged(picked);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: checkoutInputDecoration(
                        context: context,
                        isDark: isDark,
                        icon: AppIcons.building,
                        label: 'Delivery City',
                        errorText: field.errorText,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedText.isEmpty
                                  ? (context.isArabicLanguage
                                        ? 'اختار المدينة'
                                        : 'Choose city')
                                  : selectedText,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: selectedText.isEmpty
                                        ? mutedColor
                                        : null,
                                    fontWeight: FontWeight.w800,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            AppIcons.arrow_down_1,
                            color: mutedColor,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (isManualCity) ...[
                const SizedBox(height: 14),
                _CheckoutAddressTextField(
                  controller: manualCityController,
                  icon: AppIcons.edit_2,
                  label: 'Enter your city',
                  validator: requiredValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 8),
                _ShippingNote(
                  isDark: isDark,
                  text: context.isArabicLanguage
                      ? 'مصاريف الشحن هتظهر دليفيري وتتحدد بعد مراجعة المدينة.'
                      : 'Shipping will show as Delivery and is confirmed after reviewing the city.',
                ),
              ],
              if (!isManualCity && selectedCity == null) ...[
                const SizedBox(height: 8),
                _ShippingNote(
                  isDark: isDark,
                  text: context.isArabicLanguage
                      ? 'مصاريف الشحن مش هتتحدد غير لما تختار مدينة متاح لها التوصيل.'
                      : 'Shipping fee is only fixed after choosing a supported delivery city.',
                ),
              ],
              const SizedBox(height: 14),
              _CheckoutAddressTextField(
                controller: streetController,
                icon: AppIcons.building_31,
                label: 'Street',
                validator: requiredValidator,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(AppIcons.location, color: mutedColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Complete address details help checkout and delivery move faster.',
                      ),
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: AppFontSizes.label,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        crossFadeState: isExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 180),
      ),
    );
  }
}

class _CollapsedAddressSummary extends StatelessWidget {
  const _CollapsedAddressSummary({
    required this.isDark,
    required this.name,
    required this.city,
  });

  final bool isDark;
  final String name;
  final String city;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final text = [
      if (name.isNotEmpty) name,
      if (city.isNotEmpty) city,
    ].join(' • ');

    return Row(
      children: [
        Icon(AppIcons.location, color: mutedColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty
                ? (context.isArabicLanguage
                      ? 'افتح لإدخال عنوان الشحن'
                      : 'Open to enter shipping address')
                : text,
            style: TextStyle(
              color: mutedColor,
              fontSize: AppFontSizes.body,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CheckoutAddressTextField extends StatelessWidget {
  const _CheckoutAddressTextField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      decoration: checkoutInputDecoration(
        context: context,
        isDark: isDark,
        icon: icon,
        label: label,
      ),
    );
  }
}

class _ShippingNote extends StatelessWidget {
  const _ShippingNote({required this.isDark, required this.text});

  final bool isDark;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          AppIcons.info_circle,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          size: 15,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
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
