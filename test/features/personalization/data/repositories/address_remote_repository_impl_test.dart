import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/personalization/data/repositories/address_remote_repository_impl.dart';
import 'package:yalla_market/features/personalization/domain/entities/address.dart';

import '../../../../helpers/domain_fixtures.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  group('AddressRemoteRepositoryImpl', () {
    test('loads address items from the API payload', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/addresses/');
        return [_apiAddressPayload];
      });
      final repository = AddressRemoteRepositoryImpl(apiClient);

      final result = await repository.getAddresses();

      result.when(
        success: (addresses) {
          expect(addresses.single.name, _apiAddressPayload['name']);
          expect(addresses.single.isDefault, isTrue);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('creates a new address with the production API contract', () async {
      late Map<String, Object?> body;
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'POST');
        expect(request.path, '/addresses/');
        body = request.data! as Map<String, Object?>;
        return [_apiAddressPayload];
      });
      final repository = AddressRemoteRepositoryImpl(apiClient);

      final result = await repository.saveAddress(
        sampleAddress.copyWith(id: ''),
      );

      expect(body, containsPair('name', sampleAddress.name));
      expect(body, containsPair('details', sampleAddress.street));
      expect(body, containsPair('latitude', sampleAddress.latitude));
      expect(body, containsPair('longitude', sampleAddress.longitude));
      expect(body, containsPair('address_type', 'apartment'));
      expect(body, containsPair('recipient_name', sampleAddress.name));
      expect(body, containsPair('recipient_phone', sampleAddress.phoneNumber));
      expect(body, containsPair('street', sampleAddress.street));
      expect(body, containsPair('is_default', sampleAddress.isDefault));
      result.when(
        success: (addresses) => expect(addresses.single.id, 'address_1'),
        failure: (failure) => fail(failure.message),
      );
    });

    test('saves an address without GPS coordinates', () async {
      late Map<String, Object?> body;
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'POST');
        body = request.data! as Map<String, Object?>;
        return [_apiAddressPayload];
      });
      final repository = AddressRemoteRepositoryImpl(apiClient);

      final result = await repository.saveAddress(
        const AddressData(
          id: '',
          name: 'Mustafa Ali',
          phoneNumber: '+201000000000',
          street: '12 Tahrir St',
          postalCode: '',
          city: 'Cairo',
          state: 'Cairo',
          country: 'Egypt',
        ),
      );

      result.when(
        success: (addresses) => expect(addresses, isNotEmpty),
        failure: (failure) => fail(failure.message),
      );
      expect(body.containsKey('latitude'), isFalse);
      expect(body.containsKey('longitude'), isFalse);
    });

    test(
      'updates an address while preserving coordinates and default',
      () async {
        late Map<String, Object?> body;
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'PATCH');
          expect(request.path, '/addresses/${sampleAddress.id}/');
          body = request.data! as Map<String, Object?>;
          return [_apiAddressPayload];
        });
        final repository = AddressRemoteRepositoryImpl(apiClient);

        final result = await repository.saveAddress(sampleAddress);

        expect(body['details'], sampleAddress.street);
        expect(body['is_default'], isTrue);
        result.when(
          success: (addresses) => expect(addresses.single.isDefault, isTrue),
          failure: (failure) => fail(failure.message),
        );
      },
    );

    test('loads the default address from its dedicated endpoint', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/addresses/default/');
        return _apiAddressPayload;
      });
      final repository = AddressRemoteRepositoryImpl(apiClient);

      final result = await repository.getSelectedAddress();

      result.when(
        success: (address) {
          expect(address?.id, 'address_1');
          expect(address?.latitude, sampleAddress.latitude);
          expect(address?.longitude, sampleAddress.longitude);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('marks an address as default', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'PATCH');
        expect(request.path, '/addresses/${sampleAddress.id}/default/');
        return [_apiAddressPayload];
      });
      final repository = AddressRemoteRepositoryImpl(apiClient);

      final result = await repository.selectAddress(sampleAddress.id);

      result.when(
        success: (addresses) => expect(addresses.single.isDefault, isTrue),
        failure: (failure) => fail(failure.message),
      );
    });

    test('parses addresses from results payload', () async {
      final apiClient = FakeApiClient((request) {
        return {
          'results': [_apiAddressPayload],
        };
      });
      final repository = AddressRemoteRepositoryImpl(apiClient);

      final result = await repository.getAddresses();

      result.when(
        success: (addresses) => expect(addresses.single.id, 'address_1'),
        failure: (failure) => fail(failure.message),
      );
    });

    test('parses addresses from data results payload', () async {
      final apiClient = FakeApiClient((request) {
        return {
          'data': {
            'results': [_apiAddressPayload],
          },
        };
      });
      final repository = AddressRemoteRepositoryImpl(apiClient);

      final result = await repository.getAddresses();

      result.when(
        success: (addresses) => expect(addresses.single.id, 'address_1'),
        failure: (failure) => fail(failure.message),
      );
    });
  });
}

const _apiAddressPayload = <String, Object?>{
  'id': 'address_1',
  'name': 'Home',
  'phone': '+201000000000',
  'details': '12 Tahrir St',
  'service_city_id': 1,
  'service_city_name': 'Cairo',
  'delivery_area_id': 2,
  'delivery_area_name': 'Nasr City',
  'delivery_area_price': '50.00',
  'manual_city': null,
  'manual_area': null,
  'latitude': '30.0444000',
  'longitude': '31.2357000',
  'is_default': true,
};
