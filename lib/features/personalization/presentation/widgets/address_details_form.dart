import 'package:flutter/material.dart';

import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../domain/entities/delivery_area.dart';
import '../controllers/address_form_coordinator.dart';
import 'address_form_fields.dart';
import 'address_header_map_type.dart';
import 'address_region_fields.dart';

class AddressDetailsForm extends StatelessWidget {
  const AddressDetailsForm({
    super.key,
    required this.region,
    required this.areas,
    required this.selectedAreaId,
    required this.usesManualArea,
    required this.isLoadingAreas,
    required this.areasError,
    required this.manualCityController,
    required this.manualAreaController,
    required this.addressType,
    required this.buildingController,
    required this.apartmentController,
    required this.floorController,
    required this.companyController,
    required this.detailsController,
    required this.phoneController,
    required this.instructionsController,
    required this.labelController,
    required this.priceLabel,
    required this.requiredField,
    required this.onRetryAreas,
    required this.onAreaChanged,
    required this.onManualAreaSelected,
    required this.onAddressTypeChanged,
  });

  final AddressRegion region;
  final List<DeliveryArea> areas;
  final int? selectedAreaId;
  final bool usesManualArea;
  final bool isLoadingAreas;
  final String? areasError;
  final TextEditingController manualCityController;
  final TextEditingController manualAreaController;
  final String addressType;
  final TextEditingController buildingController;
  final TextEditingController apartmentController;
  final TextEditingController floorController;
  final TextEditingController companyController;
  final TextEditingController detailsController;
  final TextEditingController phoneController;
  final TextEditingController instructionsController;
  final TextEditingController labelController;
  final String Function(double? price) priceLabel;
  final FormFieldValidator<String> requiredField;
  final VoidCallback onRetryAreas;
  final ValueChanged<int> onAreaChanged;
  final VoidCallback onManualAreaSelected;
  final ValueChanged<String> onAddressTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (region.isServiceCity)
          ServiceCityFields(
            regionName: region.name,
            areas: areas,
            selectedAreaId: selectedAreaId,
            usesManualArea: usesManualArea,
            isLoading: isLoadingAreas,
            error: areasError,
            manualAreaController: manualAreaController,
            priceLabel: priceLabel,
            requiredField: requiredField,
            onRetry: onRetryAreas,
            onAreaChanged: onAreaChanged,
            onManualSelected: onManualAreaSelected,
          )
        else
          GeneralRegionFields(
            manualCityController: manualCityController,
            manualAreaController: manualAreaController,
            requiredField: requiredField,
          ),
        const SizedBox(height: 14),
        AddressTypeSelector(
          value: addressType,
          onChanged: onAddressTypeChanged,
        ),
        const SizedBox(height: 14),
        ..._addressTypeFields(),
        const SizedBox(height: 10),
        AddressTextField(
          controller: detailsController,
          icon: AppIcons.location,
          label: 'Street',
          validator: requiredField,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        AddressTextField(
          controller: phoneController,
          icon: AppIcons.mobile,
          label: 'Mobile phone number',
          validator: requiredField,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        AddressTextField(
          controller: instructionsController,
          icon: AppIcons.edit_2,
          label: 'Additional instructions (optional)',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        AddressTextField(
          controller: labelController,
          icon: AppIcons.location,
          label: 'Address label (optional)',
          hintText: 'Family home',
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('Name this address so you can identify it easily.'),
          style: TextStyle(
            color: addressSecondaryTextColor(context),
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  List<Widget> _addressTypeFields() {
    if (addressType == 'house') {
      return [
        AddressTextField(
          controller: buildingController,
          icon: AppIcons.home,
          label: 'House name',
          validator: requiredField,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        AddressTextField(
          controller: floorController,
          icon: AppIcons.building,
          label: 'Floor (optional)',
          textInputAction: TextInputAction.next,
        ),
      ];
    }

    if (addressType == 'office') {
      return [
        AddressTextField(
          controller: buildingController,
          icon: AppIcons.building_31,
          label: 'Building name',
          validator: requiredField,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        _pairedFields(
          first: AddressTextField(
            controller: companyController,
            icon: AppIcons.building,
            label: 'Company',
            validator: requiredField,
            textInputAction: TextInputAction.next,
          ),
          second: AddressTextField(
            controller: floorController,
            icon: AppIcons.building,
            label: 'Floor',
            validator: requiredField,
            textInputAction: TextInputAction.next,
          ),
        ),
      ];
    }

    return [
      AddressTextField(
        controller: buildingController,
        icon: AppIcons.building_31,
        label: 'Building name',
        validator: requiredField,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 10),
      _pairedFields(
        first: AddressTextField(
          controller: apartmentController,
          icon: AppIcons.home,
          label: 'Apartment number',
          validator: requiredField,
          textInputAction: TextInputAction.next,
        ),
        second: AddressTextField(
          controller: floorController,
          icon: AppIcons.building,
          label: 'Floor',
          validator: requiredField,
          textInputAction: TextInputAction.next,
        ),
      ),
    ];
  }

  Widget _pairedFields({required Widget first, required Widget second}) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }
}
