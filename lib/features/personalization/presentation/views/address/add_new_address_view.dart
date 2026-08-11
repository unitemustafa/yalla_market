import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/localization/app_translations.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../location/domain/entities/city_data.dart';
import '../../../../location/domain/services/device_location_service.dart';
import '../../../../location/presentation/cubit/location_cubit.dart';
import '../../../../personalization/domain/entities/delivery_area.dart';
import '../../../../personalization/domain/usecases/delivery_area_usecases.dart';
import '../../../domain/repositories/map_geocoding_repository.dart';
import '../../controllers/address_form_coordinator.dart';
import '../../controllers/user_profile_controller.dart';
import '../../cubit/address_cubit.dart';
import '../../cubit/address_state.dart';
import 'address_entry.dart';
import 'address_location_picker_view.dart';
import '../../widgets/address_details_form.dart';
import '../../widgets/address_header_map_type.dart';

class AddNewAddressView extends StatefulWidget {
  const AddNewAddressView({
    super.key,
    this.address,
    this.initialCoordinates,
    this.initialLocation,
    this.locationDataSource,
    this.geocodingDataSource,
    this.getDeliveryAreas,
    this.initialCity,
  });

  final AddressEntry? address;
  final DeviceCoordinates? initialCoordinates;
  final SelectedMapLocation? initialLocation;
  final DeviceLocationService? locationDataSource;
  final MapGeocodingRepository? geocodingDataSource;
  final GetDeliveryAreasUseCase? getDeliveryAreas;
  final CityData? initialCity;

  @override
  State<AddNewAddressView> createState() => _AddNewAddressViewState();
}

class _AddNewAddressViewState extends State<AddNewAddressView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _detailsController;
  late final TextEditingController _buildingController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _floorController;
  late final TextEditingController _companyController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _labelController;
  late final TextEditingController _manualCityController;
  late final TextEditingController _manualAreaController;
  GetDeliveryAreasUseCase? _getDeliveryAreas;
  bool _isSaving = false;
  bool _isLoadingAreas = false;
  String? _areasError;
  List<DeliveryArea> _deliveryAreas = const [];
  int? _selectedDeliveryAreaId;
  bool _usesManualArea = false;
  late SelectedMapLocation? _selectedMapLocation;
  late String _addressType;
  CityData? _formCity;
  bool _formCityInitialized = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    final profilePhone = UserProfileController.instance.phone;

    _nameController = TextEditingController(text: address?.recipientName ?? '');
    _phoneController = TextEditingController(
      text: profilePhone.isNotEmpty ? profilePhone : address?.phoneNumber ?? '',
    );
    _detailsController = TextEditingController(text: address?.details ?? '');
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
    _labelController = TextEditingController(
      text: address?.label ?? address?.name ?? '',
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
    _selectedMapLocation =
        widget.initialLocation ??
        (widget.initialCoordinates == null
            ? AddressFormCoordinator.locationFromAddress(address)
            : SelectedMapLocation(
                latitude: widget.initialCoordinates!.latitude,
                longitude: widget.initialCoordinates!.longitude,
              ));

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
    _buildingController.dispose();
    _apartmentController.dispose();
    _floorController.dispose();
    _companyController.dispose();
    _instructionsController.dispose();
    _labelController.dispose();
    _manualCityController.dispose();
    _manualAreaController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_formCityInitialized) return;
    final locationState = context.read<LocationCubit>().state;
    final addressCityId = widget.address?.serviceCityId;
    CityData? addressCity;
    if (addressCityId != null) {
      for (final city in locationState.availableCities) {
        if (city.serviceCityId == addressCityId) {
          addressCity = city;
          break;
        }
      }
    }
    _formCity =
        widget.initialCity ??
        addressCity ??
        AddressFormCoordinator.resolveServiceCity(
          locationState.selectedCity,
          locationState.availableCities,
        );
    _formCityInitialized = true;
  }

  AddressRegion _region(BuildContext context) {
    return AddressFormCoordinator.regionFor(
      city: _formCity,
      address: widget.address,
      arabic: context.isArabicLanguage,
    );
  }

  CityData? _selectedCity(BuildContext context) {
    return _formCity;
  }

  void _syncInitialRegionFields() {
    if (!mounted) return;

    final region = _region(context);
    final address = widget.address;
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
        final locationArea = _selectedMapLocation == null
            ? null
            : AddressFormCoordinator.matchingArea(
                activeAreas,
                _selectedMapLocation!,
              );
        final selectedAreaExists =
            _selectedDeliveryAreaId == null ||
            activeAreas.any((area) => area.id == _selectedDeliveryAreaId);
        setState(() {
          _deliveryAreas = activeAreas;
          if (locationArea != null) {
            _selectedDeliveryAreaId = locationArea.id;
            _usesManualArea = false;
          } else if (!selectedAreaExists) {
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
    if (region.isServiceCity && _selectedMapLocation == null) {
      CustomSnackBar.showError(
        context: context,
        title: 'Address update failed',
        message: context.tr('Choose location on map'),
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

  AddressEntry _addressFromForm(AddressRegion region) {
    return AddressFormCoordinator.buildAddress(
      existingAddress: widget.address,
      region: region,
      selectedArea: _selectedArea,
      selectedDeliveryAreaId: _selectedDeliveryAreaId,
      usesManualArea: _usesManualArea,
      selectedMapLocation: _selectedMapLocation,
      addressType: _addressType,
      values: AddressFormValues(
        phone: _phoneController.text.trim(),
        details: _detailsController.text.trim(),
        building: _buildingController.text.trim(),
        apartment: _apartmentController.text.trim(),
        floor: _floorController.text.trim(),
        company: _companyController.text.trim(),
        instructions: _instructionsController.text.trim(),
        label: _labelController.text.trim(),
        manualCity: _manualCityController.text.trim(),
        manualArea: _manualAreaController.text.trim(),
        recipientName: _nameController.text.trim(),
      ),
    );
  }

  Future<void> _changeMapLocation() async {
    final locationDataSource =
        widget.locationDataSource ?? sl<DeviceLocationService>();
    final geocodingDataSource =
        widget.geocodingDataSource ?? sl<MapGeocodingRepository>();
    final selectedCity = _formCity;
    final result = await Navigator.push<SelectedMapLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressLocationPickerView(
          locationDataSource: locationDataSource,
          geocodingDataSource: geocodingDataSource,
          fallbackCoordinates: _mapFallbackCoordinates(selectedCity),
          selectedCity: selectedCity,
          initialLocation: _selectedMapLocation,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final matchingArea = _matchingArea(result);
    setState(() {
      _selectedMapLocation = result;
      _selectedDeliveryAreaId = matchingArea?.id;
      _usesManualArea = matchingArea == null;
      if (matchingArea == null && _manualAreaController.text.trim().isEmpty) {
        _manualAreaController.text =
            result.formattedAddress?.split(',').first.trim() ?? '';
      }
    });
  }

  DeliveryArea? _matchingArea(SelectedMapLocation location) {
    return AddressFormCoordinator.matchingArea(_deliveryAreas, location);
  }

  DeviceCoordinates _mapFallbackCoordinates(CityData? city) {
    return AddressFormCoordinator.mapFallbackCoordinates(
      city: city,
      area: _selectedArea,
    );
  }

  DeliveryArea? get _selectedArea {
    return AddressFormCoordinator.selectedArea(
      _deliveryAreas,
      _selectedDeliveryAreaId,
    );
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
    final backgroundColor = isDark ? AppColors.darkBackground : Colors.white;
    final region = _region(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: AppActionButton(
          label: _isEditing ? 'Save Changes' : 'Save address',
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveAddress,
          fullWidth: true,
          verticalPadding: 10,
          textStyle: const TextStyle(
            fontSize: AppFontSizes.bodyLarge,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 760
                ? 640.0
                : constraints.maxWidth;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AddressPageHeader(
                          title: _isEditing ? 'Edit Address' : 'New address',
                          onBack: () => Navigator.maybePop(context),
                        ),
                        const SizedBox(height: 10),
                        AddressMapPreview(
                          location: _selectedMapLocation,
                          fallback: _mapFallbackCoordinates(
                            _selectedCity(context),
                          ),
                          onTap: _changeMapLocation,
                        ),
                        const SizedBox(height: 10),
                        AddressDetailsForm(
                          region: region,
                          areas: _deliveryAreas,
                          selectedAreaId: _selectedDeliveryAreaId,
                          usesManualArea: _usesManualArea,
                          isLoadingAreas: _isLoadingAreas,
                          areasError: _areasError,
                          manualCityController: _manualCityController,
                          manualAreaController: _manualAreaController,
                          addressType: _addressType,
                          buildingController: _buildingController,
                          apartmentController: _apartmentController,
                          floorController: _floorController,
                          companyController: _companyController,
                          detailsController: _detailsController,
                          phoneController: _phoneController,
                          instructionsController: _instructionsController,
                          labelController: _labelController,
                          priceLabel: _priceLabel,
                          requiredField: _requiredField,
                          onRetryAreas: _loadAreasIfNeeded,
                          onAreaChanged: (areaId) {
                            setState(() {
                              _selectedDeliveryAreaId = areaId;
                              _usesManualArea = false;
                            });
                          },
                          onManualAreaSelected: () {
                            setState(() {
                              _selectedDeliveryAreaId = null;
                              _usesManualArea = true;
                            });
                          },
                          onAddressTypeChanged: (value) =>
                              setState(() => _addressType = value),
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
