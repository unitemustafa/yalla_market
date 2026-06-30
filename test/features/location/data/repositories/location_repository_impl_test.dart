import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/location/data/datasources/device_location_data_source.dart';
import 'package:yalla_market/features/location/data/datasources/location_preferences.dart';
import 'package:yalla_market/features/location/data/repositories/location_repository_impl.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';

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

    test('keeps a separate selected city for each user', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        const _FakeDeviceLocationDataSource(),
      );

      await repository.activateUser('user-1');
      await repository.saveSelectedCity(
        const CityData(name: 'Cairo', slug: 'cairo'),
      );
      await repository.activateUser('user-2');
      final secondUserBeforeSelection = await repository.getSelectedCity();
      await repository.saveSelectedCity(CityData.general);
      await repository.activateUser('user-1');
      final firstUserCity = await repository.getSelectedCity();
      await repository.activateUser('user-2');
      final secondUserCity = await repository.getSelectedCity();

      secondUserBeforeSelection.when(
        success: (city) => expect(city, isNull),
        failure: (failure) => fail(failure.message),
      );
      firstUserCity.when(
        success: (city) => expect(city?.slug, 'cairo'),
        failure: (failure) => fail(failure.message),
      );
      secondUserCity.when(
        success: (city) => expect(city?.isGeneral, isTrue),
        failure: (failure) => fail(failure.message),
      );
    });

    test('moves the legacy saved city into the active user scope', () async {
      SharedPreferences.setMockInitialValues({
        LocationPreferences.selectedCitySlugKey: 'cairo',
        LocationPreferences.selectedCityNameKey: 'Cairo',
        LocationPreferences.selectedRegionSourceKey: 'MANUAL',
        LocationPreferences.citySelectionSeenKey: true,
      });
      final preferences = LocationPreferences();
      final repository = LocationRepositoryImpl(
        preferences,
        const _FakeDeviceLocationDataSource(),
      );

      await repository.activateUser('user-1');
      final cityResult = await repository.getSelectedCity();
      final seenResult = await repository.hasSeenCitySelection();

      cityResult.when(
        success: (city) => expect(city?.slug, 'cairo'),
        failure: (failure) => fail(failure.message),
      );
      seenResult.when(
        success: (seen) => expect(seen, isTrue),
        failure: (failure) => fail(failure.message),
      );
    });

    test('uses the cities already supported by the Flutter app', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        const _FakeDeviceLocationDataSource(),
      );

      final result = await repository.getAvailableCities();

      result.when(
        success: (cities) {
          expect(cities, CityData.dashboardRegions);
          expect(cities.every((city) => !city.isGeneral), isTrue);
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('detects GPS city locally without a backend request', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        const _FakeDeviceLocationDataSource(cityName: 'Cairo'),
      );

      final result = await repository.detectCurrentLocation();

      result.when(
        success: (city) {
          expect(city.slug, 'cairo');
          expect(city.source, RegionSource.gps);
        },
        failure: (failure) => fail(failure.message),
      );
    });

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
