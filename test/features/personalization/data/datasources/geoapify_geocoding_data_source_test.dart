import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/personalization/data/datasources/geoapify_geocoding_data_source.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  test(
    'autocomplete sends map-center proximity and parses five items',
    () async {
      final apiClient = FakeApiClient((request) {
        expect(request.path, '/locations/geocoding/autocomplete/');
        expect(request.queryParameters, {
          'q': 'Cairo',
          'latitude': 30.0444,
          'longitude': 31.2357,
          'lang': 'en',
        });
        return {
          'items': List.generate(
            5,
            (index) => {
              'place_id': 'place-$index',
              'formatted_address': 'Address $index',
              'latitude': 30 + index / 100,
              'longitude': 31 + index / 100,
            },
          ),
        };
      });
      final source = GeoapifyGeocodingDataSource(apiClient);

      final results = await source.autocomplete(
        query: 'Cairo',
        latitude: 30.0444,
        longitude: 31.2357,
        language: 'en',
      );

      expect(results, hasLength(5));
      expect(results.first.placeId, 'place-0');
      expect(results.first.displayAddress, 'Address 0');
    },
  );

  test('reverse returns optional normalized location', () async {
    final apiClient = FakeApiClient((request) {
      expect(request.path, '/locations/geocoding/reverse/');
      return {
        'location': {
          'place_id': 'geo-cairo',
          'formatted_address': 'Cairo, Egypt',
          'latitude': 30.0444,
          'longitude': 31.2357,
          'result_type': 'city',
        },
      };
    });
    final source = GeoapifyGeocodingDataSource(apiClient);

    final result = await source.reverse(
      latitude: 30.0444,
      longitude: 31.2357,
      language: 'ar',
    );

    expect(result?.formattedAddress, 'Cairo, Egypt');
    expect(result?.placeId, 'geo-cairo');
  });
}
