import '../../../../location/domain/entities/city_data.dart';
import '../../../domain/entities/address.dart';

bool isAddressAvailableForCity(AddressData address, CityData? selectedCity) {
  if (selectedCity == null) return false;
  if (selectedCity.isGeneral) return address.serviceCityId == null;

  final serviceCityId = selectedCity.serviceCityId;
  if (serviceCityId == null) return false;
  return address.serviceCityId == serviceCityId;
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
  selected ??= addresses.first;

  return isAddressAvailableForCity(selected, selectedCity) ? selected : null;
}
