import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/localization/app_translations.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../location/data/datasources/device_location_data_source.dart';
import '../../../../location/domain/entities/city_data.dart';
import '../../../../location/presentation/cubit/location_cubit.dart';
import '../../../../personalization/domain/entities/address.dart';
import '../../../../personalization/domain/entities/delivery_area.dart';
import '../../../../personalization/domain/usecases/delivery_area_usecases.dart';
import '../../controllers/user_profile_controller.dart';
import '../../cubit/address_cubit.dart';
import '../../cubit/address_state.dart';
import 'address_entry.dart';
import 'address_map_picker_view.dart';

class AddNewAddressView extends StatefulWidget {
  const AddNewAddressView({
    super.key,
    this.address,
    this.isCreating = false,
    this.locationDataSource,
    this.getDeliveryAreas,
  });

  final AddressEntry? address;
  final bool isCreating;
  final DeviceLocationDataSource? locationDataSource;
  final GetDeliveryAreasUseCase? getDeliveryAreas;

  @override
  State<AddNewAddressView> createState() => _AddNewAddressViewState();
}

class _AddNewAddressViewState extends State<AddNewAddressView> {
  final _formKey = GlobalKey<FormState>();
  late AddressData? _addressSeed;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _detailsController;
  late final TextEditingController _recipientNameController;
  late final TextEditingController _buildingController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _floorController;
  late final TextEditingController _companyController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _manualCityController;
  late final TextEditingController _manualAreaController;
  String _addressType = 'apartment';
  GetDeliveryAreasUseCase? _getDeliveryAreas;
  bool _isSaving = false;
  bool _isLoadingAreas = false;
  String? _areasError;
  List<DeliveryArea> _deliveryAreas = const [];
  int? _selectedDeliveryAreaId;
  bool _usesManualArea = false;

  bool get _isEditing => widget.address != null && !widget.isCreating;

  @override
  void initState() {
    super.initState();
    _addressSeed = widget.address;
    final address = _addressSeed;
    final profilePhone = UserProfileController.instance.phone;

    _nameController = TextEditingController(text: address?.name ?? '');
    _phoneController = TextEditingController(
      text: profilePhone.isNotEmpty ? profilePhone : address?.phoneNumber ?? '',
    );
    _detailsController = TextEditingController(text: address?.details ?? '');
    _recipientNameController = TextEditingController(
      text: address?.recipientName.isNotEmpty == true
          ? address!.recipientName
          : address?.name ?? '',
    );
    _buildingController = TextEditingController(
      text: address?.buildingName ?? '',
    );
    _apartmentController = TextEditingController(
      text: address?.apartmentNumber ?? '',
    );
    _floorController = TextEditingController(text: address?.floor ?? '');
    _companyController = TextEditingController(
      text: address?.companyName ?? '',
    );
    _instructionsController = TextEditingController(
      text: address?.additionalInstructions ?? '',
    );
    _addressType = address?.addressType ?? 'apartment';
    _manualCityController = TextEditingController(
      text: address?.manualCity ?? '',
    );
    _manualAreaController = TextEditingController(
      text: address?.manualArea ?? '',
    );
    _selectedDeliveryAreaId = address?.deliveryAreaId;
    _usesManualArea =
        address?.serviceCityId != null &&
        address?.deliveryAreaId == null &&
        (address?.manualArea?.trim().isNotEmpty ?? false);
    _getDeliveryAreas = widget.getDeliveryAreas;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncInitialRegionFields();
      _loadAreasIfNeeded();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _detailsController.dispose();
    _recipientNameController.dispose();
    _buildingController.dispose();
    _apartmentController.dispose();
    _floorController.dispose();
    _companyController.dispose();
    _instructionsController.dispose();
    _manualCityController.dispose();
    _manualAreaController.dispose();
    super.dispose();
  }

  _AddressRegion _region(BuildContext context) {
    final address = _addressSeed;
    CityData? city;
    try {
      city = context.read<LocationCubit>().state.selectedCity;
    } catch (_) {
      city = null;
    }
    if (city != null && city.isGeneral) {
      return const _AddressRegion.general();
    }
    if (city != null && !city.isGeneral && city.serviceCityId != null) {
      return _AddressRegion.serviceCity(
        id: city.serviceCityId!,
        name: city.displayName(arabic: context.isArabicLanguage),
      );
    }

    if (address?.serviceCityId != null) {
      return _AddressRegion.serviceCity(
        id: address!.serviceCityId!,
        name: address.serviceCityName ?? address.cityLabel,
      );
    }

    return const _AddressRegion.general();
  }

  void _syncInitialRegionFields() {
    if (!mounted) return;

    final region = _region(context);
    final address = _addressSeed;
    if (address == null) return;

    if (!region.isServiceCity) {
      if (_manualCityController.text.trim().isEmpty) {
        _manualCityController.text = address.cityLabel;
      }
      if (_manualAreaController.text.trim().isEmpty) {
        _manualAreaController.text = address.areaLabel;
      }
      setState(() {
        _selectedDeliveryAreaId = null;
        _usesManualArea = false;
      });
      return;
    }

    if (address.serviceCityId != region.serviceCityId) {
      setState(() {
        _selectedDeliveryAreaId = null;
        _usesManualArea = false;
      });
    }
  }

  Future<void> _loadAreasIfNeeded() async {
    if (!mounted) return;
    if (_hasResolvedLocation) return;
    final region = _region(context);
    if (!region.isServiceCity) return;
    final getDeliveryAreas = _getDeliveryAreas ??=
        sl<GetDeliveryAreasUseCase>();

    setState(() {
      _isLoadingAreas = true;
      _areasError = null;
    });

    final result = await getDeliveryAreas(region.serviceCityId!);
    if (!mounted) return;

    result.when(
      success: (areas) {
        final activeAreas = areas.where((area) => area.isActive).toList();
        final selectedAreaExists =
            _selectedDeliveryAreaId == null ||
            activeAreas.any((area) => area.id == _selectedDeliveryAreaId);
        setState(() {
          _deliveryAreas = activeAreas;
          if (!selectedAreaExists) {
            _selectedDeliveryAreaId = null;
            _usesManualArea = false;
          }
          _isLoadingAreas = false;
        });
      },
      failure: (failure) {
        setState(() {
          _areasError = failure.message;
          _isLoadingAreas = false;
        });
      },
    );
  }

  Future<void> _saveAddress() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSaving) return;

    final region = _region(context);
    if (!_hasResolvedLocation &&
        region.isServiceCity &&
        !_usesManualArea &&
        _selectedDeliveryAreaId == null) {
      CustomSnackBar.showError(
        context: context,
        title: 'Address update failed',
        message: context.tr('Choose a delivery area.'),
      );
      return;
    }

    setState(() => _isSaving = true);
    final address = _addressFromForm(region);
    final saved = await context.read<AddressCubit>().saveAddress(address);
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (!saved) {
      final state = context.read<AddressCubit>().state;
      CustomSnackBar.showError(
        context: context,
        title: 'Address update failed',
        message: state is AddressFailure
            ? state.message
            : context.tr('Could not update addresses.'),
      );
      return;
    }

    CustomSnackBar.showSuccess(
      context: context,
      title: _isEditing ? 'Address updated' : 'Address saved',
      message: address.name,
    );
    Navigator.pop(context, address);
  }

  AddressData _addressFromForm(_AddressRegion region) {
    final existingAddress = _addressSeed;
    if (_hasResolvedLocation && existingAddress != null) {
      return existingAddress.copyWith(
        name: _nameController.text.trim(),
        label: _nameController.text.trim(),
        recipientName: _recipientNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        street: _detailsController.text.trim(),
        buildingName: _buildingController.text.trim(),
        apartmentNumber: _addressType == 'apartment'
            ? _apartmentController.text.trim()
            : '',
        floor: _addressType == 'apartment' ? _floorController.text.trim() : '',
        companyName: _addressType == 'office'
            ? _companyController.text.trim()
            : '',
        additionalInstructions: _instructionsController.text.trim(),
        addressType: _addressType,
      );
    }
    final selectedArea = _selectedArea;
    final serviceCityId = region.serviceCityId;
    final isServiceCity = region.isServiceCity;
    final selectedDeliveryAreaId = isServiceCity && !_usesManualArea
        ? _selectedDeliveryAreaId
        : null;
    final selectedDeliveryAreaName = isServiceCity && !_usesManualArea
        ? selectedArea?.name ?? existingAddress?.deliveryAreaName
        : null;
    final selectedDeliveryAreaPrice = isServiceCity && !_usesManualArea
        ? selectedArea?.deliveryPrice ?? existingAddress?.deliveryAreaPrice
        : null;
    final manualCity = isServiceCity ? null : _manualCityController.text.trim();
    final manualArea = isServiceCity
        ? (_usesManualArea ? _manualAreaController.text.trim() : null)
        : _manualAreaController.text.trim();

    return AddressData(
      id: existingAddress?.id ?? '',
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      street: _detailsController.text.trim(),
      district: selectedDeliveryAreaName ?? manualArea ?? '',
      postalCode: existingAddress?.postalCode ?? '',
      city: isServiceCity ? region.name : manualCity ?? '',
      state: '',
      country: '',
      latitude: existingAddress?.latitude,
      longitude: existingAddress?.longitude,
      isDefault: existingAddress?.isDefault ?? false,
      manualCity: manualCity,
      manualArea: manualArea,
      serviceCityId: serviceCityId,
      serviceCityName: isServiceCity ? region.name : null,
      deliveryAreaId: selectedDeliveryAreaId,
      deliveryAreaName: selectedDeliveryAreaName,
      deliveryAreaPrice: selectedDeliveryAreaPrice,
      deliveryType: 'delivery',
      addressType: _addressType,
      recipientName: _recipientNameController.text.trim(),
      buildingName: _buildingController.text.trim(),
      apartmentNumber: _apartmentController.text.trim(),
      floor: _floorController.text.trim(),
      companyName: _companyController.text.trim(),
      additionalInstructions: _instructionsController.text.trim(),
      label: _nameController.text.trim(),
    );
  }

  bool get _hasResolvedLocation =>
      _addressSeed?.latitude != null &&
      _addressSeed?.longitude != null &&
      _addressSeed?.fulfillmentType != null;

  Future<void> _editLocation() async {
    final updated = await Navigator.push<AddressData>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressMapPickerView(initialAddress: _addressSeed),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _addressSeed = updated);
  }

  DeliveryArea? get _selectedArea {
    final selectedId = _selectedDeliveryAreaId;
    if (selectedId == null) return null;
    for (final area in _deliveryAreas) {
      if (area.id == selectedId) return area;
    }
    return null;
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('This field is required');
    }
    return null;
  }

  String _priceLabel(double? price) {
    if (price == null) {
      return context.tr('Delivery price will be confirmed later');
    }
    final value = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return context.tr('EGP {price}').replaceAll('{price}', value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);
    final region = _region(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 760
                ? 640.0
                : constraints.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        PageTopBar(
                          title: _isEditing ? 'Edit Address' : 'Add Address',
                          subtitle: _isEditing
                              ? 'Update this delivery location'
                              : 'Save a delivery location',
                        ),
                        const SizedBox(height: 18),
                        _AddressFormCard(
                          isDark: isDark,
                          children: [
                            if (_hasResolvedLocation)
                              _ResolvedLocationTile(
                                address: _addressSeed!,
                                onEdit: _editLocation,
                              ),
                            _AddressTypeSelector(
                              value: _addressType,
                              onChanged: (value) {
                                setState(() => _addressType = value);
                              },
                            ),
                            _AddressTextField(
                              controller: _recipientNameController,
                              icon: AppIcons.user,
                              label: 'Recipient name',
                              validator: _requiredField,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddressTextField(
                              controller: _nameController,
                              icon: AppIcons.location,
                              label: 'Address name',
                              hintText: 'Home, Work, Other address',
                              validator: _requiredField,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddressTextField(
                              controller: _phoneController,
                              icon: AppIcons.mobile,
                              label: 'Phone Number',
                              readOnly: _phoneController.text.isNotEmpty,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddressTextField(
                              controller: _detailsController,
                              icon: AppIcons.building_31,
                              label: 'Street',
                              hintText: 'Street name',
                              validator: _requiredField,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddressTextField(
                              controller: _buildingController,
                              icon: AppIcons.building,
                              label: _addressType == 'house'
                                  ? 'House / villa number'
                                  : 'Building name or number',
                              validator: _requiredField,
                              textInputAction: TextInputAction.next,
                            ),
                            if (_addressType == 'apartment') ...[
                              _AddressTextField(
                                controller: _apartmentController,
                                icon: AppIcons.building,
                                label: 'Apartment number',
                                validator: _requiredField,
                                textInputAction: TextInputAction.next,
                              ),
                              _AddressTextField(
                                controller: _floorController,
                                icon: AppIcons.building,
                                label: 'Floor',
                                validator: _requiredField,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                            if (_addressType == 'office')
                              _AddressTextField(
                                controller: _companyController,
                                icon: AppIcons.building,
                                label: 'Company name',
                                validator: _requiredField,
                                textInputAction: TextInputAction.next,
                              ),
                            _AddressTextField(
                              controller: _instructionsController,
                              icon: AppIcons.edit_2,
                              label: 'Additional instructions (optional)',
                              hintText: 'Landmark, entrance, or delivery note',
                              textInputAction: TextInputAction.done,
                            ),
                            if (!_hasResolvedLocation && region.isServiceCity)
                              _ServiceCityFields(
                                regionName: region.name,
                                areas: _deliveryAreas,
                                selectedAreaId: _selectedDeliveryAreaId,
                                usesManualArea: _usesManualArea,
                                isLoading: _isLoadingAreas,
                                error: _areasError,
                                manualAreaController: _manualAreaController,
                                priceLabel: _priceLabel,
                                requiredField: _requiredField,
                                onRetry: _loadAreasIfNeeded,
                                onAreaChanged: (areaId) {
                                  setState(() {
                                    _selectedDeliveryAreaId = areaId;
                                    _usesManualArea = false;
                                  });
                                },
                                onManualSelected: () {
                                  setState(() {
                                    _selectedDeliveryAreaId = null;
                                    _usesManualArea = true;
                                  });
                                },
                              )
                            else if (!_hasResolvedLocation)
                              _GeneralRegionFields(
                                manualCityController: _manualCityController,
                                manualAreaController: _manualAreaController,
                                requiredField: _requiredField,
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AppActionButton(
                          label: _isEditing ? 'Save Changes' : 'Save',
                          icon: AppIcons.tick_circle,
                          isLoading: _isSaving,
                          onPressed: _isSaving ? null : _saveAddress,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResolvedLocationTile extends StatelessWidget {
  const _ResolvedLocationTile({required this.address, required this.onEdit});

  final AddressData address;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDirect = address.fulfillmentType == 'direct';
    final price = address.deliveryAreaPrice;
    final eta = address.etaMinMinutes;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDirect ? Colors.green : Colors.orange).withValues(
          alpha: 0.09,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isDirect ? Colors.green : Colors.orange).withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDirect ? Icons.delivery_dining : Icons.local_shipping_outlined,
            color: isDirect ? Colors.green.shade700 : Colors.orange.shade800,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDirect
                      ? 'توصيل مباشر إلى ${address.deliveryAreaName ?? address.cityLabel}'
                      : 'شحن خارجي إلى هذا الموقع',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (isDirect && (price != null || eta != null))
                  Text(
                    [
                      if (price != null) '${price.toStringAsFixed(0)} ج.م',
                      if (eta != null)
                        '$eta-${address.etaMaxMinutes ?? eta} دقيقة',
                    ].join(' • '),
                  ),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('تعديل')),
        ],
      ),
    );
  }
}

class _AddressTypeSelector extends StatelessWidget {
  const _AddressTypeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('apartment', 'شقة', Icons.apartment),
      ('house', 'منزل', Icons.home_outlined),
      ('office', 'مكتب', Icons.work_outline),
    ];
    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              selected: value == options[index].$1,
              onSelected: (_) => onChanged(options[index].$1),
              avatar: Icon(options[index].$3, size: 18),
              label: Text(options[index].$2),
            ),
          ),
        ],
      ],
    );
  }
}

class _AddressRegion {
  const _AddressRegion._({
    required this.isServiceCity,
    required this.name,
    this.serviceCityId,
  });

  const _AddressRegion.serviceCity({required int id, required String name})
    : this._(isServiceCity: true, serviceCityId: id, name: name);

  const _AddressRegion.general()
    : this._(isServiceCity: false, name: 'Other city');

  final bool isServiceCity;
  final int? serviceCityId;
  final String name;
}

class _ServiceCityFields extends StatelessWidget {
  const _ServiceCityFields({
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
        ? _manualAreaOption
        : selectedArea?.id.toString();
    final cityLabel = context
        .tr('City: {name}')
        .replaceAll('{name}', regionName);
    final fixedPriceLabel = selectedArea == null
        ? null
        : context
              .tr('Fixed delivery price: {price}')
              .replaceAll('{price}', priceLabel(selectedArea.deliveryPrice));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadOnlyInfoTile(icon: AppIcons.building, label: cityLabel),
        const SizedBox(height: 14),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          _RetryTile(message: error!, onRetry: onRetry)
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
                  : priceLabel(selectedArea.deliveryPrice);

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
                  if (picked == _manualAreaOption) {
                    onManualSelected();
                    return;
                  }
                  final id = int.tryParse(picked);
                  if (id != null) onAreaChanged(id);
                },
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: _inputDecoration(
                    context: context,
                    icon: AppIcons.location,
                    label: 'Delivery area',
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
                                color: _secondaryTextColor(context),
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
                        color: _secondaryTextColor(context),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (usesManualArea) ...[
          const SizedBox(height: 14),
          _AddressTextField(
            controller: manualAreaController,
            icon: AppIcons.edit_2,
            label: 'Enter your area name',
            validator: requiredField,
            textInputAction: TextInputAction.done,
          ),
        ],
        const SizedBox(height: 10),
        _DeliveryNote(
          text: usesManualArea
              ? context.tr('Delivery price will be confirmed later')
              : selectedArea == null
              ? context.tr('Choose a delivery area to see the price')
              : fixedPriceLabel!,
        ),
      ],
    );
  }
}

class _GeneralRegionFields extends StatelessWidget {
  const _GeneralRegionFields({
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
        _DeliveryNote(
          text: context.tr(
            'Your city is outside the current service cities. Enter your city and area manually.',
          ),
        ),
        const SizedBox(height: 14),
        _AddressTextField(
          controller: manualCityController,
          icon: AppIcons.building,
          label: 'City',
          validator: requiredField,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _AddressTextField(
          controller: manualAreaController,
          icon: AppIcons.location,
          label: 'Area',
          validator: requiredField,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 10),
        _DeliveryNote(
          text: context.tr('Delivery price will be confirmed later'),
        ),
      ],
    );
  }
}

const _manualAreaOption = '__manual_area__';

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
      return _DeliveryAreaPickerSheet(
        areas: areas,
        selectedValue: selectedValue,
        priceLabel: priceLabel,
        isDark: isDark,
      );
    },
  );
}

class _DeliveryAreaPickerSheet extends StatelessWidget {
  const _DeliveryAreaPickerSheet({
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
                      return _DeliveryAreaOptionTile(
                        icon: AppIcons.edit_2,
                        title: context.tr('My area is not listed'),
                        subtitle: context.tr(
                          'Delivery price will be confirmed later',
                        ),
                        isDark: isDark,
                        isSelected: selectedValue == _manualAreaOption,
                        onTap: () => Navigator.pop(context, _manualAreaOption),
                      );
                    }

                    final area = areas[index];
                    final value = area.id.toString();
                    return _DeliveryAreaOptionTile(
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

class _DeliveryAreaOptionTile extends StatelessWidget {
  const _DeliveryAreaOptionTile({
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
    final mutedColor = _secondaryTextColor(context);
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

class _AddressFormCard extends StatelessWidget {
  const _AddressFormCard({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _AddressTextField extends StatelessWidget {
  const _AddressTextField({
    required this.controller,
    required this.icon,
    required this.label,
    this.hintText,
    this.validator,
    this.textInputAction,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: readOnly,
      textInputAction: textInputAction,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      decoration: _inputDecoration(
        context: context,
        icon: icon,
        label: label,
        hintText: hintText,
      ),
    );
  }
}

class _ReadOnlyInfoTile extends StatelessWidget {
  const _ReadOnlyInfoTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryTile extends StatelessWidget {
  const _RetryTile({required this.message, required this.onRetry});

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

class _DeliveryNote extends StatelessWidget {
  const _DeliveryNote({required this.text});

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

InputDecoration _inputDecoration({
  required BuildContext context,
  required IconData icon,
  required String label,
  String? hintText,
  String? errorText,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    prefixIcon: Icon(icon),
    labelText: context.tr(label),
    hintText: hintText == null ? null : context.tr(hintText),
    hintStyle: TextStyle(
      color: _secondaryTextColor(context),
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

Color _secondaryTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
}
