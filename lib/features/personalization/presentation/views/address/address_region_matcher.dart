import '../../../../location/domain/entities/city_data.dart';
import '../../../domain/entities/address.dart';

bool isAddressAvailableForCity(AddressData address, CityData? selectedCity) {
  if (!isAddressDeliverable(address)) return false;
  if (selectedCity == null) return false;
  if (selectedCity.isGeneral) {
    final deliveryType = address.deliveryType?.trim().toLowerCase();
    return address.serviceCityId == null &&
        (deliveryType == null ||
            deliveryType.isEmpty ||
            deliveryType == 'delivery');
  }

  final serviceCityId = selectedCity.serviceCityId;
  if (serviceCityId == null) return false;
  return address.serviceCityId == serviceCityId;
}

bool isAddressDeliverable(AddressData address) {
  if (address.serviceCityIsActive == false) return false;
  return address.deliveryAreaId == null ||
      address.deliveryAreaIsActive != false;
}

AddressData? selectedAvailableAddressForCity({
  required List<AddressData> addresses,
  required String? selectedAddressId,
  required CityData? selectedCity,
}) {
  if (addresses.isEmpty) return null;

  AddressData? selected;
  if (selectedAddressId != null) {
    for (final address in addresses) {
      if (address.id == selectedAddressId) {
        selected = address;
        break;
      }
    }
  }

  if (selected != null && isAddressAvailableForCity(selected, selectedCity)) {
    return selected;
  }

  for (final address in addresses) {
    if (address.isDefault && isAddressAvailableForCity(address, selectedCity)) {
      return address;
    }
  }

  for (final address in addresses) {
    if (isAddressAvailableForCity(address, selectedCity)) return address;
  }

  return null;
}
