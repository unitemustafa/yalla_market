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

      expect(body, {
        'line1': sampleAddress.street,
        'city': sampleAddress.city,
        'state': sampleAddress.state,
        'country': sampleAddress.country,
        'latitude': sampleAddress.latitude,
        'longitude': sampleAddress.longitude,
        'is_default': sampleAddress.isDefault,
      });
      result.when(
        success: (addresses) => expect(addresses.single.id, sampleAddress.id),
        failure: (failure) => fail(failure.message),
      );
    });

    test('rejects saving an address without GPS coordinates', () async {
      final apiClient = FakeApiClient((request) {
        fail('The API must not be called without coordinates.');
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
        success: (_) => fail('Saving without coordinates should fail.'),
        failure: (failure) => expect(
          failure.message,
          'Turn on GPS and allow location access before saving the address.',
        ),
      );
      expect(apiClient.requests, isEmpty);
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

        expect(body['latitude'], sampleAddress.latitude);
        expect(body['longitude'], sampleAddress.longitude);
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
          expect(address?.id, sampleAddress.id);
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
  });
}

const _apiAddressPayload = <String, Object?>{
  'id': 'address_1',
  'name': '12 Tahrir St, Cairo, Cairo, Egypt',
  'phoneNumber': '+201000000000',
  'street': '12 Tahrir St, Cairo, Cairo, Egypt',
  'city': '',
  'state': '',
  'country': 'Egypt',
  'postalCode': '',
  'latitude': '30.0444000',
  'longitude': '31.2357000',
  'is_default': true,
};
