import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/location/data/datasources/device_location_data_source.dart';
import 'package:yalla_market/features/location/data/datasources/location_preferences.dart';
import 'package:yalla_market/features/location/data/repositories/location_repository_impl.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  group('LocationRepositoryImpl', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and loads the selected city from preferences', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        _FakeDeviceLocationDataSource(),
      );

      final saveResult = await repository.saveSelectedCity(
        const CityData(name: 'Hurghada', slug: 'hurghada'),
      );
      final loadResult = await repository.getSelectedCity();

      saveResult.when(
        success: (city) => expect(city.slug, 'hurghada'),
        failure: (failure) => fail(failure.message),
      );
      loadResult.when(
        success: (city) => expect(city?.name, 'Hurghada'),
        failure: (failure) => fail(failure.message),
      );
    });

    test('loads active cities from the backend with localized names', () async {
      final apiClient = FakeApiClient((request) {
        expect(request.method, 'GET');
        expect(request.path, '/locations/cities/');
        return [
          {
            'id': 7,
            'name': 'Mansoura',
            'name_ar': 'المنصورة',
            'slug': 'mansoura',
          },
        ];
      });
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        const _FakeDeviceLocationDataSource(),
        apiClient,
      );

      final result = await repository.getAvailableCities();

      result.when(
        success: (cities) {
          expect(cities, hasLength(1));
          expect(cities.single.slug, 'mansoura');
          expect(cities.single.nameAr, 'المنصورة');
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test(
      'resolves GPS coordinates through the backend coverage endpoint',
      () async {
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'POST');
          expect(request.path, '/locations/resolve/');
          expect(request.data, {'latitude': 30.0444, 'longitude': 31.2357});
          return {
            'mode': 'city',
            'display_name': 'Cairo',
            'city': {
              'id': 1,
              'name': 'Cairo',
              'name_ar': 'القاهرة',
              'slug': 'cairo',
            },
          };
        });
        final repository = LocationRepositoryImpl(
          LocationPreferences(),
          const _FakeDeviceLocationDataSource(),
          apiClient,
        );

        final result = await repository.detectCurrentLocation();

        result.when(
          success: (city) {
            expect(city.slug, 'cairo');
            expect(city.source, RegionSource.gps);
          },
          failure: (failure) => fail(failure.message),
        );
      },
    );

    test('saves and loads a custom selected city from preferences', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        _FakeDeviceLocationDataSource(),
      );

      final saveResult = await repository.saveSelectedCity(
        const CityData(name: 'Aswan', slug: 'aswan'),
      );
      final loadResult = await repository.getSelectedCity();

      saveResult.when(
        success: (city) => expect(city.name, 'Aswan'),
        failure: (failure) => fail(failure.message),
      );
      loadResult.when(
        success: (city) {
          expect(city?.name, 'Aswan');
          expect(city?.slug, 'aswan');
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test(
      'uses current location and normalizes it to a supported city',
      () async {
        final repository = LocationRepositoryImpl(
          LocationPreferences(),
          _FakeDeviceLocationDataSource(cityName: 'Al Qahirah Governorate'),
        );

        final result = await repository.useCurrentLocation();

        result.when(
          success: (city) => expect(city.slug, 'cairo'),
          failure: (failure) => fail(failure.message),
        );
      },
    );

    test('detects current location without saving it', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        _FakeDeviceLocationDataSource(cityName: 'Al Qahirah Governorate'),
      );

      final detectResult = await repository.detectCurrentLocation();
      final loadResult = await repository.getSelectedCity();

      detectResult.when(
        success: (city) => expect(city.slug, 'cairo'),
        failure: (failure) => fail(failure.message),
      );
      loadResult.when(
        success: (city) => expect(city, isNull),
        failure: (failure) => fail(failure.message),
      );
    });

    test('tracks whether city selection was already shown', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        _FakeDeviceLocationDataSource(),
      );

      final initialResult = await repository.hasSeenCitySelection();
      final markResult = await repository.markCitySelectionSeen();
      final updatedResult = await repository.hasSeenCitySelection();

      initialResult.when(
        success: (seen) => expect(seen, isFalse),
        failure: (failure) => fail(failure.message),
      );
      markResult.when(
        success: (_) {},
        failure: (failure) => fail(failure.message),
      );
      updatedResult.when(
        success: (seen) => expect(seen, isTrue),
        failure: (failure) => fail(failure.message),
      );
    });

    test('saving a city marks city selection as seen', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        _FakeDeviceLocationDataSource(),
      );

      await repository.saveSelectedCity(
        const CityData(name: 'Hurghada', slug: 'hurghada'),
      );
      final result = await repository.hasSeenCitySelection();

      result.when(
        success: (seen) => expect(seen, isTrue),
        failure: (failure) => fail(failure.message),
      );
    });

    test('clears the saved city and selection status', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        _FakeDeviceLocationDataSource(),
      );

      await repository.saveSelectedCity(
        const CityData(name: 'Hurghada', slug: 'hurghada'),
      );
      final clearResult = await repository.clearSelectedCity();
      final cityResult = await repository.getSelectedCity();
      final seenResult = await repository.hasSeenCitySelection();

      clearResult.when(
        success: (_) {},
        failure: (failure) => fail(failure.message),
      );
      cityResult.when(
        success: (city) => expect(city, isNull),
        failure: (failure) => fail(failure.message),
      );
      seenResult.when(
        success: (seen) => expect(seen, isFalse),
        failure: (failure) => fail(failure.message),
      );
    });

    test(
      'falls back to general when current location is outside supported regions',
      () async {
        final repository = LocationRepositoryImpl(
          LocationPreferences(),
          _FakeDeviceLocationDataSource(cityName: 'Aswan'),
        );

        final result = await repository.useCurrentLocation();

        result.when(
          success: (city) {
            expect(city.name, 'Aswan');
            expect(city.slug, CityData.generalSlug);
            expect(city.source, RegionSource.general);
          },
          failure: (failure) => fail(failure.message),
        );

        final loadResult = await repository.getSelectedCity();
        loadResult.when(
          success: (city) {
            expect(city?.name, 'Aswan');
            expect(city?.slug, CityData.generalSlug);
          },
          failure: (failure) => fail(failure.message),
        );
      },
    );
  });
}

class _FakeDeviceLocationDataSource implements DeviceLocationDataSource {
  const _FakeDeviceLocationDataSource({this.cityName});

  final String? cityName;

  @override
  Future<String?> resolveCurrentCityName({
    bool requestPermission = true,
  }) async {
    return cityName;
  }

  @override
  Future<DeviceCoordinates> resolveCurrentCoordinates({
    bool requestPermission = true,
  }) async {
    return const DeviceCoordinates(30.0444, 31.2357);
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}
