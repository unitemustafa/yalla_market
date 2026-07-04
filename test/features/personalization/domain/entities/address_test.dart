import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/personalization/domain/entities/address.dart';

void main() {
  group('AddressData', () {
    test('reads name and details as separate fields', () {
      final address = AddressData.fromJson({
        'id': 12,
        'name': 'Home',
        'details': 'Army Street',
      });

      expect(address.name, 'Home');
      expect(address.details, 'Army Street');
    });

    test('supports line1 and street aliases', () {
      expect(AddressData.fromJson({'line1': 'Line 1'}).details, 'Line 1');
      expect(AddressData.fromJson({'street': 'Street'}).details, 'Street');
    });

    test('reads manual city and area', () {
      final address = AddressData.fromJson({
        'manual_city': 'Mansoura',
        'manual_area': 'University District',
      });

      expect(address.manualCity, 'Mansoura');
      expect(address.manualArea, 'University District');
      expect(address.cityLabel, 'Mansoura');
      expect(address.areaLabel, 'University District');
    });

    test('reads fixed delivery area fields', () {
      final address = AddressData.fromJson({
        'service_city': {'id': '1', 'name': 'Cairo'},
        'delivery_area': {'id': '2', 'name': 'Nasr City'},
        'delivery_area_price': '50.00',
      });

      expect(address.serviceCityId, 1);
      expect(address.serviceCityName, 'Cairo');
      expect(address.deliveryAreaId, 2);
      expect(address.deliveryAreaName, 'Nasr City');
      expect(address.deliveryAreaPrice, 50);
    });

    test('handles null delivery price and legacy addresses', () {
      final address = AddressData.fromJson({
        'id': 'legacy',
        'fullName': 'Old Home',
        'street': 'Old Street',
        'delivery_area_price': null,
      });

      expect(address.name, 'Old Home');
      expect(address.details, 'Old Street');
      expect(address.deliveryAreaPrice, isNull);
    });
  });
}
