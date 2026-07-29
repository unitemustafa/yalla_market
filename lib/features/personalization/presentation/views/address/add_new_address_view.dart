import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/localization/app_translations.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/config/maptiler_map_config.dart';
import '../../../../../core/config/app_map_tile_provider.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../location/data/datasources/device_location_data_source.dart';
import '../../../../location/domain/entities/city_data.dart';
import '../../../../location/domain/utils/geo_coverage.dart';
import '../../../../location/presentation/cubit/location_cubit.dart';
import '../../../../personalization/domain/entities/address.dart';
import '../../../../personalization/domain/entities/delivery_area.dart';
import '../../../../personalization/domain/usecases/delivery_area_usecases.dart';
import '../../../data/datasources/geoapify_geocoding_data_source.dart';
import '../../controllers/user_profile_controller.dart';
import '../../cubit/address_cubit.dart';
import '../../cubit/address_state.dart';
import 'address_entry.dart';
import 'address_location_picker_view.dart';

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
  final DeviceLocationDataSource? locationDataSource;
  final MapGeocodingDataSource? geocodingDataSource;
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
            ? _locationFromAddress(address)
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
        _resolveServiceCity(
          locationState.selectedCity,
          locationState.availableCities,
        );
    _formCityInitialized = true;
  }

  CityData? _resolveServiceCity(
    CityData? selectedCity,
    List<CityData> availableCities,
  ) {
    if (selectedCity == null) return null;
    final serviceCities = availableCities.where(
      (city) => !city.isGeneral && city.serviceCityId != null,
    );
    final selectedKnownCity = CityData.fromName(selectedCity.name);
    for (final city in serviceCities) {
      if (selectedCity.serviceCityId != null &&
          city.serviceCityId == selectedCity.serviceCityId) {
        return city;
      }
      final candidateKnownCity = CityData.fromName(city.name);
      if (selectedKnownCity != null &&
          candidateKnownCity?.slug == selectedKnownCity.slug) {
        return city;
      }
      if (city.name.trim().toLowerCase() ==
          selectedCity.name.trim().toLowerCase()) {
        return city;
      }
    }
    return selectedCity;
  }

  _AddressRegion _region(BuildContext context) {
    final address = widget.address;
    final city = _formCity;
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
            : _matchingAreaFrom(activeAreas, _selectedMapLocation!);
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
    final label = _labelController.text.trim();
    final fallbackName = switch (_addressType) {
      'house' => 'Home',
      'office' => 'Work',
      _ => 'Apartment',
    };

    return AddressData(
      id: existingAddress?.id ?? '',
      name: label.isNotEmpty ? label : fallbackName,
      phoneNumber: _phoneController.text.trim(),
      street: _detailsController.text.trim(),
      district: selectedDeliveryAreaName ?? manualArea ?? '',
      postalCode: existingAddress?.postalCode ?? '',
      city: isServiceCity ? region.name : manualCity ?? '',
      state: '',
      country: '',
      latitude: _selectedMapLocation?.latitude ?? existingAddress?.latitude,
      longitude: _selectedMapLocation?.longitude ?? existingAddress?.longitude,
      formattedAddress: _selectedMapLocation == null
          ? existingAddress?.formattedAddress
          : _selectedMapLocation!.formattedAddress,
      placeId: _selectedMapLocation == null
          ? existingAddress?.placeId
          : _selectedMapLocation!.placeId,
      isDefault: existingAddress?.isDefault ?? false,
      manualCity: manualCity,
      manualArea: manualArea,
      serviceCityId: serviceCityId,
      serviceCityName: isServiceCity ? region.name : null,
      deliveryAreaId: selectedDeliveryAreaId,
      deliveryAreaName: selectedDeliveryAreaName,
      deliveryAreaPrice: selectedDeliveryAreaPrice,
      deliveryType: selectedDeliveryAreaId == null ? 'delivery' : 'fixed_area',
      fulfillmentType: selectedDeliveryAreaId == null
          ? 'external_shipping'
          : 'direct',
      addressType: _addressType,
      recipientName: _nameController.text.trim(),
      buildingName: _buildingController.text.trim(),
      apartmentNumber: _apartmentController.text.trim(),
      floor: _floorController.text.trim(),
      companyName: _companyController.text.trim(),
      additionalInstructions: _instructionsController.text.trim(),
      label: label,
    );
  }

  SelectedMapLocation? _locationFromAddress(AddressEntry? address) {
    final latitude = address?.latitude;
    final longitude = address?.longitude;
    if (latitude == null || longitude == null) return null;
    return SelectedMapLocation(
      latitude: latitude,
      longitude: longitude,
      formattedAddress: address?.formattedAddress,
      placeId: address?.placeId,
    );
  }

  Future<void> _changeMapLocation() async {
    final locationDataSource =
        widget.locationDataSource ?? sl<DeviceLocationDataSource>();
    final geocodingDataSource =
        widget.geocodingDataSource ?? sl<MapGeocodingDataSource>();
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
    return _matchingAreaFrom(_deliveryAreas, location);
  }

  DeliveryArea? _matchingAreaFrom(
    List<DeliveryArea> areas,
    SelectedMapLocation location,
  ) {
    for (final area in areas) {
      final hasCoverage =
          area.boundaryGeoJson != null ||
          area.boundaryBbox != null ||
          (area.centerLatitude != null &&
              area.centerLongitude != null &&
              area.radiusKm != null);
      if (!hasCoverage) continue;
      if (geoCoverageContains(
        latitude: location.latitude,
        longitude: location.longitude,
        boundaryGeoJson: area.boundaryGeoJson,
        boundaryBbox: area.boundaryBbox,
        centerLatitude: area.centerLatitude,
        centerLongitude: area.centerLongitude,
        radiusKm: area.radiusKm,
      )) {
        return area;
      }
    }
    return null;
  }

  DeviceCoordinates _fallbackCoordinates(CityData? city) {
    final knownCity = CityData.fromName(city?.name);
    if (knownCity?.slug == 'cairo') {
      return const DeviceCoordinates(30.0444, 31.2357);
    }
    if (knownCity?.slug == 'sharm-el-sheikh') {
      return const DeviceCoordinates(27.9158, 34.3299);
    }
    final latitude = city?.centerLatitude;
    final longitude = city?.centerLongitude;
    if (latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180) {
      return DeviceCoordinates(latitude, longitude);
    }
    return const DeviceCoordinates(30.0444, 31.2357);
  }

  DeviceCoordinates _mapFallbackCoordinates(CityData? city) {
    final area = _selectedArea;
    final latitude = area?.centerLatitude;
    final longitude = area?.centerLongitude;
    if (latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180) {
      return DeviceCoordinates(latitude, longitude);
    }
    return _fallbackCoordinates(city);
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
                        _AddressPageHeader(
                          title: _isEditing ? 'Edit Address' : 'New address',
                          onBack: () => Navigator.maybePop(context),
                        ),
                        const SizedBox(height: 10),
                        _AddressMapPreview(
                          location: _selectedMapLocation,
                          fallback: _mapFallbackCoordinates(
                            _selectedCity(context),
                          ),
                          onTap: _changeMapLocation,
                        ),
                        const SizedBox(height: 10),
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
                        const SizedBox(height: 14),
                        _AddressTypeSelector(
                          value: _addressType,
                          onChanged: (value) =>
                              setState(() => _addressType = value),
                        ),
                        const SizedBox(height: 14),
                        if (_addressType == 'apartment') ...[
                          _AddressTextField(
                            controller: _buildingController,
                            icon: AppIcons.building_31,
                            label: 'Building name',
                            validator: _requiredField,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _AddressTextField(
                                  controller: _apartmentController,
                                  icon: AppIcons.home,
                                  label: 'Apartment number',
                                  validator: _requiredField,
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AddressTextField(
                                  controller: _floorController,
                                  icon: AppIcons.building,
                                  label: 'Floor',
                                  validator: _requiredField,
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                            ],
                          ),
                        ] else if (_addressType == 'house') ...[
                          _AddressTextField(
                            controller: _buildingController,
                            icon: AppIcons.home,
                            label: 'House name',
                            validator: _requiredField,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 10),
                          _AddressTextField(
                            controller: _floorController,
                            icon: AppIcons.building,
                            label: 'Floor (optional)',
                            textInputAction: TextInputAction.next,
                          ),
                        ] else ...[
                          _AddressTextField(
                            controller: _buildingController,
                            icon: AppIcons.building_31,
                            label: 'Building name',
                            validator: _requiredField,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _AddressTextField(
                                  controller: _companyController,
                                  icon: AppIcons.building,
                                  label: 'Company',
                                  validator: _requiredField,
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AddressTextField(
                                  controller: _floorController,
                                  icon: AppIcons.building,
                                  label: 'Floor',
                                  validator: _requiredField,
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        _AddressTextField(
                          controller: _detailsController,
                          icon: AppIcons.location,
                          label: 'Street',
                          validator: _requiredField,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 10),
                        _AddressTextField(
                          controller: _phoneController,
                          icon: AppIcons.mobile,
                          label: 'Mobile phone number',
                          validator: _requiredField,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 10),
                        _AddressTextField(
                          controller: _instructionsController,
                          icon: AppIcons.edit_2,
                          label: 'Additional instructions (optional)',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 10),
                        _AddressTextField(
                          controller: _labelController,
                          icon: AppIcons.location,
                          label: 'Address label (optional)',
                          hintText: 'Family home',
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr(
                            'Name this address so you can identify it easily.',
                          ),
                          style: TextStyle(
                            color: _secondaryTextColor(context),
                            fontSize: 12,
                            height: 1.35,
                          ),
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

class _AddressPageHeader extends StatelessWidget {
  const _AddressPageHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            context.tr(title),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: AppFontSizes.bodyLarge,
              fontWeight: FontWeight.w900,
            ),
          ),
          PositionedDirectional(
            start: 0,
            child: SizedBox.square(
              dimension: 42,
              child: Material(
                color: Colors.transparent,
                shape: CircleBorder(
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onBack,
                  iconSize: 22,
                  icon: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressMapPreview extends StatefulWidget {
  const _AddressMapPreview({
    required this.location,
    required this.fallback,
    required this.onTap,
  });

  final SelectedMapLocation? location;
  final DeviceCoordinates fallback;
  final VoidCallback onTap;

  @override
  State<_AddressMapPreview> createState() => _AddressMapPreviewState();
}

class _AddressMapPreviewState extends State<_AddressMapPreview> {
  late final NetworkTileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileProvider = createAppMapTileProvider();
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = widget.location?.coordinates ?? widget.fallback;
    return Semantics(
      button: true,
      label: context.tr('Choose location on map'),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 104,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (MapTilerMapConfig.isConfigured)
                  IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          coordinates.latitude,
                          coordinates.longitude,
                        ),
                        initialZoom: 14,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: MapTilerMapConfig.tileUrl(),
                          userAgentPackageName:
                              MapTilerMapConfig.userAgentPackageName,
                          tileProvider: _tileProvider,
                          maxNativeZoom: 20,
                          panBuffer: 0,
                          keepBuffer: 1,
                        ),
                      ],
                    ),
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.map_outlined,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                  ),
                const Center(
                  child: Icon(
                    Icons.location_pin,
                    color: AppColors.primary,
                    size: 40,
                    shadows: [
                      Shadow(
                        color: Color(0x44000000),
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
    const types = [
      ('apartment', 'Apartment', AppIcons.building_31),
      ('house', 'House', AppIcons.home),
      ('office', 'Office', AppIcons.bag_2),
    ];
    return Row(
      children: [
        for (var index = 0; index < types.length; index++) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: _AddressTypeButton(
              selected: value == types[index].$1,
              icon: types[index].$3,
              label: context.tr(types[index].$2),
              onTap: () => onChanged(types[index].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _AddressTypeButton extends StatelessWidget {
  const _AddressTypeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppColors.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: AppFontSizes.body,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: _inputDecoration(
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
                  : '${priceLabel(selectedArea.deliveryPrice)} • '
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
          const SizedBox(height: 10),
          _AddressTextField(
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

class _AddressTextField extends StatelessWidget {
  const _AddressTextField({
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
      decoration: _inputDecoration(
        context: context,
        icon: icon,
        label: label,
        hintText: hintText,
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
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    prefixIcon: Icon(icon, size: 20),
    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    labelText: context.tr(label),
    labelStyle: TextStyle(
      color: _secondaryTextColor(context),
      fontSize: AppFontSizes.label,
      fontWeight: FontWeight.w600,
    ),
    hintText: hintText == null ? null : context.tr(hintText),
    hintStyle: TextStyle(
      color: _secondaryTextColor(context),
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

Color _secondaryTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
}
