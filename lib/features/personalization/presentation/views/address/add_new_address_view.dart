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

class AddNewAddressView extends StatefulWidget {
  const AddNewAddressView({
    super.key,
    this.address,
    this.locationDataSource,
    this.getDeliveryAreas,
  });

  final AddressEntry? address;
  final DeviceLocationDataSource? locationDataSource;
  final GetDeliveryAreasUseCase? getDeliveryAreas;

  @override
  State<AddNewAddressView> createState() => _AddNewAddressViewState();
}

class _AddNewAddressViewState extends State<AddNewAddressView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _detailsController;
  late final TextEditingController _manualCityController;
  late final TextEditingController _manualAreaController;
  GetDeliveryAreasUseCase? _getDeliveryAreas;
  bool _isSaving = false;
  bool _isLoadingAreas = false;
  String? _areasError;
  List<DeliveryArea> _deliveryAreas = const [];
  int? _selectedDeliveryAreaId;
  bool _usesManualArea = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    final profilePhone = UserProfileController.instance.phone;

    _nameController = TextEditingController(text: address?.name ?? '');
    _phoneController = TextEditingController(
      text: profilePhone.isNotEmpty ? profilePhone : address?.phoneNumber ?? '',
    );
    _detailsController = TextEditingController(text: address?.details ?? '');
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAreasIfNeeded());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _detailsController.dispose();
    _manualCityController.dispose();
    _manualAreaController.dispose();
    super.dispose();
  }

  _AddressRegion _region(BuildContext context) {
    final address = widget.address;
    if (address?.serviceCityId != null) {
      return _AddressRegion.serviceCity(
        id: address!.serviceCityId!,
        name: address.serviceCityName ?? address.cityLabel,
      );
    }

    CityData? city;
    try {
      city = context.read<LocationCubit>().state.selectedCity;
    } catch (_) {
      city = null;
    }
    if (city != null && !city.isGeneral && city.serviceCityId != null) {
      return _AddressRegion.serviceCity(
        id: city.serviceCityId!,
        name: city.displayName(arabic: context.isArabicLanguage),
      );
    }

    return const _AddressRegion.general();
  }

  Future<void> _loadAreasIfNeeded() async {
    if (!mounted) return;
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
        setState(() {
          _deliveryAreas = areas.where((area) => area.isActive).toList();
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
    if (region.isServiceCity &&
        !_usesManualArea &&
        _selectedDeliveryAreaId == null) {
      CustomSnackBar.showError(
        context: context,
        title: 'Address update failed',
        message: 'Choose a delivery area.',
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
            : 'Could not update addresses.',
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
    final existingAddress = widget.address;
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
    );
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
      return context.isArabicLanguage
          ? 'دليفيري - يحدد لاحقا'
          : 'Delivery - confirmed later';
    }
    final value = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return context.isArabicLanguage ? '$value ج.م' : 'EGP $value';
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
                            _AddressTextField(
                              controller: _nameController,
                              icon: AppIcons.user,
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
                              label: 'Address details',
                              hintText: 'Street, building, floor, landmark',
                              validator: _requiredField,
                              textInputAction: TextInputAction.next,
                            ),
                            if (region.isServiceCity)
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
                            else
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

class _AddressRegion {
  const _AddressRegion._({
    required this.isServiceCity,
    required this.name,
    this.serviceCityId,
  });

  const _AddressRegion.serviceCity({required int id, required String name})
    : this._(isServiceCity: true, serviceCityId: id, name: name);

  const _AddressRegion.general()
    : this._(isServiceCity: false, name: 'مدينة أخرى');

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadOnlyInfoTile(icon: AppIcons.building, label: 'City: $regionName'),
        const SizedBox(height: 14),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          _RetryTile(message: error!, onRetry: onRetry)
        else
          DropdownButtonFormField<String>(
            initialValue: usesManualArea
                ? _manualAreaOption
                : selectedAreaId?.toString(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('This field is required');
              }
              return null;
            },
            decoration: _inputDecoration(
              context: context,
              icon: AppIcons.location,
              label: 'Delivery area',
            ),
            items: [
              for (final area in areas)
                DropdownMenuItem(
                  value: area.id.toString(),
                  child: Text(
                    '${area.name} - ${priceLabel(area.deliveryPrice)}',
                  ),
                ),
              const DropdownMenuItem(
                value: _manualAreaOption,
                child: Text('منطقتي غير موجودة'),
              ),
            ],
            onChanged: (value) {
              if (value == _manualAreaOption) {
                onManualSelected();
                return;
              }
              final id = int.tryParse(value ?? '');
              if (id != null) onAreaChanged(id);
            },
          ),
        if (usesManualArea) ...[
          const SizedBox(height: 14),
          _AddressTextField(
            controller: manualAreaController,
            icon: AppIcons.edit_2,
            label: 'اكتب اسم منطقتك',
            validator: requiredField,
            textInputAction: TextInputAction.done,
          ),
        ],
        const SizedBox(height: 10),
        _DeliveryNote(
          text: usesManualArea
              ? 'سعر التوصيل: دليفيري - يحدد لاحقا'
              : selectedArea == null
              ? 'اختر منطقة التوصيل لعرض السعر'
              : 'توصيل بسعر محدد: ${priceLabel(selectedArea.deliveryPrice)}',
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
        const _DeliveryNote(
          text:
              'مدينتك غير موجودة ضمن مدن الخدمة الحالية. اكتب بيانات مدينتك ومنطقتك يدويا.',
        ),
        const SizedBox(height: 14),
        _AddressTextField(
          controller: manualCityController,
          icon: AppIcons.building,
          label: 'المدينة',
          validator: requiredField,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _AddressTextField(
          controller: manualAreaController,
          icon: AppIcons.location,
          label: 'المنطقة',
          validator: requiredField,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 10),
        const _DeliveryNote(text: 'سعر التوصيل: دليفيري - يحدد لاحقا'),
      ],
    );
  }
}

const _manualAreaOption = '__manual_area__';

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
              fontSize: 12,
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
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    prefixIcon: Icon(icon),
    labelText: context.tr(label),
    hintText: hintText == null ? null : context.tr(hintText),
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
