import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/data/repositories/shipping_company_remote_repository_impl.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  test(
    'loads valid shipping companies for the requested service city',
    () async {
      final apiClient = FakeApiClient(
        (request) => [
          {'id': 4, 'name': 'Fast Ship', 'logo_url': '/media/logo.webp'},
        ],
      );
      final repository = ShippingCompanyRemoteRepositoryImpl(apiClient);

      final result = await repository.getForCity(9);

      result.when(
        success: (companies) {
          expect(companies, hasLength(1));
          expect(companies.single.name, 'Fast Ship');
          expect(companies.single.logoUrl, '/media/logo.webp');
        },
        failure: (failure) => fail(failure.message),
      );
      expect(apiClient.requests.single.path, '/locations/shipping-companies/');
      expect(apiClient.requests.single.queryParameters, {'service_city_id': 9});
    },
  );

  test('does not treat a malformed response as an empty list', () async {
    final repository = ShippingCompanyRemoteRepositoryImpl(
      FakeApiClient((request) => {'unexpected': true}),
    );

    final result = await repository.getForCity(9);

    result.when(
      success: (_) => fail('Malformed responses must not bypass selection.'),
      failure: (failure) => expect(failure.message, isNotEmpty),
    );
  });
}
