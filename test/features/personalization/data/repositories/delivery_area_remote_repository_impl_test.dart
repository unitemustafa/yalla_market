import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/personalization/data/repositories/delivery_area_remote_repository_impl.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('DeliveryAreaRemoteRepositoryImpl', () {
    test('sends service_city_id as a query parameter', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/locations/delivery-areas/');
        expect(request.queryParameters, {'service_city_id': 1});
        return [_areaPayload(deliveryPrice: '50.00')];
      });
      final repository = DeliveryAreaRemoteRepositoryImpl(apiClient);

      final result = await repository.getDeliveryAreas(1);

      result.when(
        success: (areas) => expect(areas.single.id, 2),
        failure: (failure) => fail(failure.message),
      );
    });

    test('parses a direct array payload', () async {
      final areas = deliveryAreasFromPayload([_areaPayload()]);

      expect(areas.single.name, 'Nasr City');
    });

    test('parses a results payload', () async {
      final areas = deliveryAreasFromPayload({
        'results': [_areaPayload()],
      });

      expect(areas.single.serviceCityId, 1);
    });

    test('parses a data results payload', () async {
      final areas = deliveryAreasFromPayload({
        'data': {
          'results': [_areaPayload()],
        },
      });

      expect(areas.single.deliveryPrice, 50);
    });

    test('parses delivery_price as a number', () async {
      final areas = deliveryAreasFromPayload([_areaPayload(deliveryPrice: 55)]);

      expect(areas.single.deliveryPrice, 55);
    });
  });
}

Map<String, Object?> _areaPayload({Object? deliveryPrice = '50.00'}) {
  return {
    'id': '2',
    'service_city_id': '1',
    'name': 'Nasr City',
    'delivery_price': deliveryPrice,
    'is_active': true,
  };
}
