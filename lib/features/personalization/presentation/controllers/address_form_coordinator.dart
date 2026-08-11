import '../../../location/domain/entities/city_data.dart';
import '../../../location/domain/services/device_location_service.dart';
import '../../../location/domain/utils/geo_coverage.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/delivery_area.dart';
import 'address_location_picker_controller.dart';

class AddressRegion {
  const AddressRegion._({
    required this.isServiceCity,
    required this.name,
    this.serviceCityId,
  });

  const AddressRegion.serviceCity({required int id, required String name})
    : this._(isServiceCity: true, serviceCityId: id, name: name);

  const AddressRegion.general()
    : this._(isServiceCity: false, name: 'Other city');

  final bool isServiceCity;
  final int? serviceCityId;
  final String name;
}

class AddressFormValues {
  const AddressFormValues({
    required this.phone,
    required this.details,
    required this.building,
    required this.apartment,
    required this.floor,
    required this.company,
    required this.instructions,
    required this.label,
    required this.manualCity,
    required this.manualArea,
    required this.recipientName,
  });

  final String phone;
  final String details;
  final String building;
  final String apartment;
  final String floor;
  final String company;
  final String instructions;
  final String label;
  final String manualCity;
  final String manualArea;
  final String recipientName;
}

class AddressFormCoordinator {
  const AddressFormCoordinator._();

  static CityData? resolveServiceCity(
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

  static AddressRegion regionFor({
    required CityData? city,
    required AddressData? address,
    required bool arabic,
  }) {
    if (city != null && city.isGeneral) {
      return const AddressRegion.general();
    }
    if (city != null && !city.isGeneral && city.serviceCityId != null) {
      return AddressRegion.serviceCity(
        id: city.serviceCityId!,
        name: city.displayName(arabic: arabic),
      );
    }
    if (address?.serviceCityId != null) {
      return AddressRegion.serviceCity(
        id: address!.serviceCityId!,
        name: address.serviceCityName ?? address.cityLabel,
      );
    }
    return const AddressRegion.general();
  }

  static AddressData buildAddress({
    required AddressData? existingAddress,
    required AddressRegion region,
    required DeliveryArea? selectedArea,
    required int? selectedDeliveryAreaId,
    required bool usesManualArea,
    required SelectedMapLocation? selectedMapLocation,
    required String addressType,
    required AddressFormValues values,
  }) {
    final isServiceCity = region.isServiceCity;
    final areaId = isServiceCity && !usesManualArea
        ? selectedDeliveryAreaId
        : null;
    final areaName = isServiceCity && !usesManualArea
        ? selectedArea?.name ?? existingAddress?.deliveryAreaName
        : null;
    final areaPrice = isServiceCity && !usesManualArea
        ? selectedArea?.deliveryPrice ?? existingAddress?.deliveryAreaPrice
        : null;
    final manualCity = isServiceCity ? null : values.manualCity;
    final manualArea = isServiceCity
        ? (usesManualArea ? values.manualArea : null)
        : values.manualArea;
    final fallbackName = switch (addressType) {
      'house' => 'Home',
      'office' => 'Work',
      _ => 'Apartment',
    };

    return AddressData(
      id: existingAddress?.id ?? '',
      name: values.label.isNotEmpty ? values.label : fallbackName,
      phoneNumber: values.phone,
      street: values.details,
      district: areaName ?? manualArea ?? '',
      postalCode: existingAddress?.postalCode ?? '',
      city: isServiceCity ? region.name : manualCity ?? '',
      state: '',
      country: '',
      latitude: selectedMapLocation?.latitude ?? existingAddress?.latitude,
      longitude: selectedMapLocation?.longitude ?? existingAddress?.longitude,
      formattedAddress: selectedMapLocation == null
          ? existingAddress?.formattedAddress
          : selectedMapLocation.formattedAddress,
      placeId: selectedMapLocation == null
          ? existingAddress?.placeId
          : selectedMapLocation.placeId,
      isDefault: existingAddress?.isDefault ?? false,
      manualCity: manualCity,
      manualArea: manualArea,
      serviceCityId: region.serviceCityId,
      serviceCityName: isServiceCity ? region.name : null,
      deliveryAreaId: areaId,
      deliveryAreaName: areaName,
      deliveryAreaPrice: areaPrice,
      deliveryType: areaId == null ? 'delivery' : 'fixed_area',
      fulfillmentType: areaId == null ? 'external_shipping' : 'direct',
      addressType: addressType,
      recipientName: values.recipientName,
      buildingName: values.building,
      apartmentNumber: values.apartment,
      floor: values.floor,
      companyName: values.company,
      additionalInstructions: values.instructions,
      label: values.label,
    );
  }

  static SelectedMapLocation? locationFromAddress(AddressData? address) {
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

  static DeliveryArea? selectedArea(List<DeliveryArea> areas, int? selectedId) {
    if (selectedId == null) return null;
    for (final area in areas) {
      if (area.id == selectedId) return area;
    }
    return null;
  }

  static DeliveryArea? matchingArea(
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

  static DeviceCoordinates fallbackCoordinates(CityData? city) {
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

  static DeviceCoordinates mapFallbackCoordinates({
    required CityData? city,
    required DeliveryArea? area,
  }) {
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
    return fallbackCoordinates(city);
  }
}
