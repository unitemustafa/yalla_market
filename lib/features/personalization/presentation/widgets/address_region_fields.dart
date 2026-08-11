import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../domain/entities/delivery_area.dart';
import 'address_form_fields.dart';

class ServiceCityFields extends StatelessWidget {
  const ServiceCityFields({
    super.key,
    required this.regionName,
    required this.areas,
    required this.selectedAreaId,
    required this.usesManualArea,
    required this.isLoading,
    required this.error,
    required this.manualAreaController,
    required this.priceLabel,
    required this.requiredField,
    required this.onRetry,
    required this.onAreaChanged,
    required this.onManualSelected,
  });

  final String regionName;
  final List<DeliveryArea> areas;
  final int? selectedAreaId;
  final bool usesManualArea;
  final bool isLoading;
  final String? error;
  final TextEditingController manualAreaController;
  final String Function(double? price) priceLabel;
  final FormFieldValidator<String> requiredField;
  final VoidCallback onRetry;
  final ValueChanged<int> onAreaChanged;
  final VoidCallback onManualSelected;

  @override
  Widget build(BuildContext context) {
    final selectedArea = areas
        .where((area) => area.id == selectedAreaId)
        .firstOrNull;
    final dropdownValue = usesManualArea
        ? manualAreaOption
        : selectedArea?.id.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: addressInputDecoration(
            context: context,
            icon: AppIcons.building,
            label: 'City',
          ),
          child: Text(
            regionName,
            style: const TextStyle(
              fontSize: AppFontSizes.body,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          AddressRetryTile(message: error!, onRetry: onRetry)
        else
          FormField<String>(
            initialValue: dropdownValue,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('This field is required');
              }
              return null;
            },
            builder: (field) {
              final selectedText = usesManualArea
                  ? context.tr('My area is not listed')
                  : selectedArea?.name ?? context.tr('Choose a delivery area');
              final selectedPriceText = usesManualArea
                  ? context.tr('Delivery price will be confirmed later')
                  : selectedArea == null
                  ? context.tr('Choose a delivery area to see the price')
                  : '${priceLabel(selectedArea.deliveryPrice)} â€¢ '
                        '${context.tr('Direct area delivery')}';

              return InkWell(
                onTap: () async {
                  final picked = await _openDeliveryAreaPicker(
                    context: context,
                    areas: areas,
                    selectedValue: field.value,
                    priceLabel: priceLabel,
                  );
                  if (picked == null) return;
                  field.didChange(picked);
                  if (picked == manualAreaOption) {
                    onManualSelected();
                    return;
                  }
                  final id = int.tryParse(picked);
                  if (id != null) onAreaChanged(id);
                },
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: addressInputDecoration(
                    context: context,
                    icon: AppIcons.location,
                    label: 'Area',
                    errorText: field.errorText,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              selectedPriceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: addressSecondaryTextColor(context),
                                fontSize: AppFontSizes.label,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        AppIcons.arrow_down_1,
                        color: addressSecondaryTextColor(context),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (usesManualArea) ...[
          const SizedBox(height: 10),
          AddressTextField(
            controller: manualAreaController,
            icon: AppIcons.edit_2,
            label: 'Enter your area name',
            validator: requiredField,
            textInputAction: TextInputAction.done,
          ),
        ],
      ],
    );
  }
}

class GeneralRegionFields extends StatelessWidget {
  const GeneralRegionFields({
    super.key,
    required this.manualCityController,
    required this.manualAreaController,
    required this.requiredField,
  });

  final TextEditingController manualCityController;
  final TextEditingController manualAreaController;
  final FormFieldValidator<String> requiredField;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DeliveryNote(
          text: context.tr(
            'Your city is outside the current service cities. Enter your city and area manually.',
          ),
        ),
        const SizedBox(height: 14),
        AddressTextField(
          controller: manualCityController,
          icon: AppIcons.building,
          label: 'City',
          validator: requiredField,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        AddressTextField(
          controller: manualAreaController,
          icon: AppIcons.location,
          label: 'Area',
          validator: requiredField,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 10),
        DeliveryNote(
          text: context.tr('Delivery price will be confirmed later'),
        ),
      ],
    );
  }
}

Future<String?> _openDeliveryAreaPicker({
  required BuildContext context,
  required List<DeliveryArea> areas,
  required String? selectedValue,
  required String Function(double? price) priceLabel,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.darkCardColor : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return DeliveryAreaPickerSheet(
        areas: areas,
        selectedValue: selectedValue,
        priceLabel: priceLabel,
        isDark: isDark,
      );
    },
  );
}
