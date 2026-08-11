import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/localization/app_translations.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../domain/entities/address.dart';
import '../../../../location/domain/entities/city_data.dart';
import '../../../../location/domain/services/device_location_service.dart';
import '../../../domain/repositories/map_geocoding_repository.dart';
import '../../../domain/usecases/delivery_area_usecases.dart';
import '../../cubit/address_cubit.dart';
import '../../cubit/address_state.dart';
import 'address_display_text.dart';
import 'address_location_picker_view.dart';
import 'address_region_matcher.dart';
import 'add_new_address_view.dart';
import 'widgets/single_address.dart';
import '../../../../location/presentation/cubit/location_cubit.dart';

class AddressesView extends StatefulWidget {
  const AddressesView({super.key, this.returnAfterSelection = false});

  final bool returnAfterSelection;

  @override
  State<AddressesView> createState() => _AddressesViewState();
}

class _AddressesViewState extends State<AddressesView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshAddresses();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshAddresses();
  }

  Future<void> _refreshAddresses() {
    return context.read<AddressCubit>().loadAddresses();
  }

  Future<void> _openAddressForm(
    BuildContext context, {
    AddressData? address,
  }) async {
    SelectedMapLocation? selectedLocation;
    CityData? formCity;
    if (address == null) {
      final locationCubit = context.read<LocationCubit>();
      final selectedCity = locationCubit.state.selectedCity;
      final citiesFuture = locationCubit.state.availableCities.isEmpty
          ? locationCubit.loadAvailableCities()
          : Future.value(locationCubit.state.availableCities);
      selectedLocation = await Navigator.push<SelectedMapLocation>(
        context,
        MaterialPageRoute(
          builder: (_) => AddressLocationPickerView(
            locationDataSource: sl<DeviceLocationService>(),
            geocodingDataSource: sl<MapGeocodingRepository>(),
            fallbackCoordinates: _fallbackCoordinates(selectedCity),
            selectedCity: selectedCity,
          ),
        ),
      );
      if (selectedLocation == null || !context.mounted) return;
      final availableCities = await citiesFuture;
      if (!context.mounted) return;
      formCity = _resolveServiceCity(selectedCity, availableCities);
    }

    await Navigator.push<AddressData>(
      context,
      MaterialPageRoute(
        builder: (_) => AddNewAddressView(
          address: address,
          initialLocation: selectedLocation,
          locationDataSource: sl<DeviceLocationService>(),
          geocodingDataSource: sl<MapGeocodingRepository>(),
          getDeliveryAreas: sl<GetDeliveryAreasUseCase>(),
          initialCity: formCity,
        ),
      ),
    );
  }

  CityData? _resolveServiceCity(
    CityData? selectedCity,
    List<CityData> availableCities,
  ) {
    if (selectedCity == null) return null;
    final selectedKnownCity = CityData.fromName(selectedCity.name);
    for (final city in availableCities) {
      if (city.isGeneral || city.serviceCityId == null) continue;
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

  Future<void> _deleteAddress(BuildContext context, AddressData address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            context.tr('Delete address?'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            context
                .tr('Remove {name} from your saved delivery locations?')
                .replaceAll('{name}', address.name),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.tr('Cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: Text(
                      context.tr('Delete'),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await context.read<AddressCubit>().deleteAddress(
      address.id,
    );
    if (!deleted || !context.mounted) return;

    CustomSnackBar.showRemoved(
      context: context,
      title: 'Address deleted',
      message: address.name,
    );
  }

  Future<void> _selectAddress(BuildContext context, AddressData address) async {
    final selected = await context.read<AddressCubit>().selectAddress(
      address.id,
    );
    if (!selected || !context.mounted) return;
    if (widget.returnAfterSelection) {
      Navigator.pop(context, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return BlocConsumer<AddressCubit, AddressState>(
      listenWhen: (previous, current) =>
          current is AddressFailure &&
          (previous is! AddressFailure || previous.message != current.message),
      listener: (context, state) {
        if (state is AddressFailure) {
          CustomSnackBar.showError(
            context: context,
            title: 'Address update failed',
            message: state.message,
          );
        }
      },
      builder: (context, state) {
        final addresses = state.addresses;
        final selectedAddressId = state.selectedAddressId;
        final isInitialLoading = state is AddressLoading && addresses.isEmpty;
        final selectedCity = context.watch<LocationCubit>().state.selectedCity;
        final availableAddresses = <AddressData>[];
        final unavailableAddresses = <AddressData>[];
        for (final address in addresses) {
          if (isAddressAvailableForCity(address, selectedCity)) {
            availableAddresses.add(address);
          } else {
            unavailableAddresses.add(address);
          }
        }
        final orderedAddresses = [
          ...availableAddresses,
          ...unavailableAddresses,
        ];
        final selectedAvailableAddress = selectedAvailableAddressForCity(
          addresses: addresses,
          selectedAddressId: selectedAddressId,
          selectedCity: selectedCity,
        );

        return Scaffold(
          backgroundColor: backgroundColor,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddressForm(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(AppIcons.add, color: Colors.white),
            label: Text(
              context.tr('Add'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: SafeArea(
            child: isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : AppRefreshIndicator(
                    onRefresh: _refreshAddresses,
                    child: ListView.separated(
                      physics: AppRefreshIndicator.scrollPhysics,
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        12.0,
                        16.0,
                        90.0,
                      ),
                      itemCount: orderedAddresses.length + 2,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const PageTopBar(
                            title: 'Addresses',
                            subtitle: 'Choose where orders should arrive',
                          );
                        }

                        if (index == 1) {
                          return _AddressSummaryCard(
                            isDark: isDark,
                            totalCount: addresses.length,
                            selectedName: selectedAvailableAddress?.name,
                          );
                        }

                        final address = orderedAddresses[index - 2];
                        final isAvailable = isAddressAvailableForCity(
                          address,
                          selectedCity,
                        );
                        final isDeliveryAvailable = isAddressDeliverable(
                          address,
                        );

                        return SingleAddress(
                          selectedAddress:
                              selectedAvailableAddress?.id == address.id,
                          isAvailable: isAvailable,
                          unavailableLabel: !isDeliveryAvailable
                              ? 'Disabled'
                              : !isAvailable
                              ? 'Not supported here'
                              : null,
                          unavailableMessage: isDeliveryAvailable
                              ? null
                              : 'Delivery is no longer available for this address',
                          name: address.name,
                          phoneNumber: address.phoneNumber,
                          address: localizedAddressText(context, address),
                          city: address.cityLabel,
                          area: address.areaLabel,
                          deliveryPriceLabel: _deliveryPriceLabel(
                            context,
                            address.deliveryAreaPrice,
                          ),
                          onTap: isAvailable
                              ? () => _selectAddress(context, address)
                              : null,
                          onEdit: () =>
                              _openAddressForm(context, address: address),
                          onDelete: () => _deleteAddress(context, address),
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }
}

String _deliveryPriceLabel(BuildContext context, double? price) {
  if (price == null) {
    return context.tr('Delivery: confirmed later');
  }
  final value = price == price.roundToDouble()
      ? price.toStringAsFixed(0)
      : price.toStringAsFixed(2);
  return context.tr('Delivery: EGP {price}').replaceAll('{price}', value);
}

class _AddressSummaryCard extends StatelessWidget {
  const _AddressSummaryCard({
    required this.isDark,
    required this.totalCount,
    required this.selectedName,
  });

  final bool isDark;
  final int totalCount;
  final String? selectedName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25273A) : const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(AppIcons.location, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.savedLocations(totalCount),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedName == null
                      ? context.tr('Add an address to start checkout faster.')
                      : context
                            .tr('{name} is selected for checkout.')
                            .replaceAll('{name}', selectedName!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
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
