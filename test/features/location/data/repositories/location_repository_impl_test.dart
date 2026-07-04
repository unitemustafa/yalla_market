import 'package:dio/dio.dart';
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

    test(
      'parses backend region options with general and service cities',
      () async {
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'GET');
          expect(request.path, '/market-region/options/');
          return {
            'options': [
              {'mode': 'general', 'label': 'General', 'service_city': null},
              {
                'mode': 'service_city',
                'label': 'القاهرة',
                'service_city': {
                  'id': 7,
                  'name': 'القاهرة',
                  'delivery_price': '0.00',
                  'is_active': true,
                },
              },
            ],
            'current_selection': null,
          };
        });
        final repository = LocationRepositoryImpl(
          LocationPreferences(),
          const _FakeDeviceLocationDataSource(),
          apiClient,
        );

        final result = await repository.getAvailableCities();

        result.when(
          success: (cities) {
            expect(cities.first.isGeneral, isTrue);
            expect(cities.last.serviceCityId, 7);
            expect(cities.last.name, 'القاهرة');
          },
          failure: (failure) => fail(failure.message),
        );
      },
    );

    test('loads null current backend region', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        const _FakeDeviceLocationDataSource(),
        FakeApiClient((request) {
          expect(request.path, '/market-region/me/');
          return {'current_selection': null};
        }),
      );

      final result = await repository.getSelectedCity();

      result.when(
        success: (city) => expect(city, isNull),
        failure: (failure) => fail(failure.message),
      );
    });

    test('loads service-city current backend region', () async {
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        const _FakeDeviceLocationDataSource(),
        FakeApiClient((request) {
          return {
            'current_selection': {
              'mode': 'service_city',
              'label': 'Cairo',
              'service_city': {
                'id': 3,
                'name': 'Cairo',
                'delivery_price': '0.00',
                'is_active': true,
              },
              'updated_at': '2026-07-04T12:00:00Z',
            },
          };
        }),
      );

      final result = await repository.getSelectedCity();

      result.when(
        success: (city) {
          expect(city?.serviceCityId, 3);
          expect(city?.name, 'Cairo');
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('patches general region through backend', () async {
      late Object? sentData;
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        const _FakeDeviceLocationDataSource(),
        FakeApiClient((request) {
          expect(request.method, 'PATCH');
          expect(request.path, '/market-region/me/');
          sentData = request.data;
          return {
            'current_selection': {
              'mode': 'general',
              'label': 'General',
              'service_city': null,
            },
          };
        }),
      );

      final result = await repository.saveSelectedCity(CityData.general);

      expect(sentData, {'mode': 'general'});
      result.when(
        success: (city) => expect(city.isGeneral, isTrue),
        failure: (failure) => fail(failure.message),
      );
    });

    test('patches service city region through backend', () async {
      late Object? sentData;
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        const _FakeDeviceLocationDataSource(),
        FakeApiClient((request) {
          sentData = request.data;
          return {
            'current_selection': {
              'mode': 'service_city',
              'label': 'Cairo',
              'service_city': {
                'id': 5,
                'name': 'Cairo',
                'delivery_price': '0.00',
                'is_active': true,
              },
            },
          };
        }),
      );

      final result = await repository.saveSelectedCity(
        const CityData(name: 'Cairo', slug: '5', serviceCityId: 5),
      );

      expect(sentData, {'mode': 'service_city', 'service_city_id': 5});
      result.when(
        success: (city) => expect(city.serviceCityId, 5),
        failure: (failure) => fail(failure.message),
      );
    });

    test(
      'parses GPS detect actions including unknown without crashing',
      () async {
        final actions = [
          'same_region',
          'suggest_switch',
          'unsupported_location',
          'select_detected_region',
          'future_action',
        ];
        var index = 0;
        final repository = LocationRepositoryImpl(
          LocationPreferences(),
          const _FakeDeviceLocationDataSource(),
          FakeApiClient((request) {
            expect(request.method, 'POST');
            expect(request.path, '/market-region/detect/');
            return {
              'action': actions[index++],
              'current_selection': null,
              'detected_region': {
                'mode': 'service_city',
                'service_city': {'id': 1, 'name': 'Cairo'},
              },
              'message': 'ok',
            };
          }),
        );

        final parsedActions = <GpsRegionAction>[];
        for (var i = 0; i < actions.length; i++) {
          final result = await repository.detectMarketRegion();
          result.when(
            success: (detection) => parsedActions.add(detection.action),
            failure: (failure) => fail(failure.message),
          );
        }

        expect(parsedActions, [
          GpsRegionAction.sameRegion,
          GpsRegionAction.suggestSwitch,
          GpsRegionAction.unsupportedLocation,
          GpsRegionAction.selectDetectedRegion,
          GpsRegionAction.unknown,
        ]);
      },
    );

    test('detect sends latitude and longitude rounded to 7 decimals', () async {
      late Object? sentData;
      final repository = LocationRepositoryImpl(
        LocationPreferences(),
        const _FakeDeviceLocationDataSource(
          coordinates: DeviceCoordinates(
            36.753800000000005,
            3.0587999999999997,
          ),
        ),
        FakeApiClient((request) {
          sentData = request.data;
          return {
            'action': 'same_region',
            'current_selection': null,
            'detected_region': null,
            'message': 'ok',
          };
        }),
      );

      final result = await repository.detectMarketRegion();

      result.when(success: (_) {}, failure: (failure) => fail(failure.message));
      expect(sentData, {'latitude': 36.7538, 'longitude': 3.0588});
    });

    test(
      'detect 400 returns failure and does not patch or save general',
      () async {
        final requests = <FakeApiRequest>[];
        final repository = LocationRepositoryImpl(
          LocationPreferences(),
          const _FakeDeviceLocationDataSource(),
          FakeApiClient((request) {
            requests.add(request);
            throw _badDetectCoordinatesException();
          }),
        );

        final result = await repository.detectMarketRegion();

        result.when(
          success: (_) => fail('Expected detection to fail.'),
          failure: (_) {},
        );
        expect(requests.map((request) => request.method), ['POST']);
      },
    );

    test('backend current service city beats cached general', () async {
      final preferences = LocationPreferences();
      await preferences.setSelectedCity(
        CityData.general.slug,
        CityData.general.name,
        source: RegionSource.general.storageValue,
      );
      final repository = LocationRepositoryImpl(
        preferences,
        const _FakeDeviceLocationDataSource(),
        FakeApiClient((request) {
          return {
            'current_selection': {
              'mode': 'service_city',
              'service_city': {'id': 1, 'name': 'الجزائر'},
            },
          };
        }),
      );

      final result = await repository.getSelectedCity();

      result.when(
        success: (city) {
          expect(city?.isGeneral, isFalse);
          expect(city?.serviceCityId, 1);
          expect(city?.name, 'الجزائر');
        },
        failure: (failure) => fail(failure.message),
      );
    });

    test('backend null current selection clears cached general', () async {
      final preferences = LocationPreferences();
      await preferences.setSelectedCity(
        CityData.general.slug,
        CityData.general.name,
        source: RegionSource.general.storageValue,
      );
      final repository = LocationRepositoryImpl(
        preferences,
        const _FakeDeviceLocationDataSource(),
        FakeApiClient((request) => {'current_selection': null}),
      );

      final result = await repository.getSelectedCity();
      final cachedResult = await LocationRepositoryImpl(
        preferences,
        const _FakeDeviceLocationDataSource(),
      ).getSelectedCity();

      result.when(
        success: (city) => expect(city, isNull),
        failure: (failure) => fail(failure.message),
      );
      cachedResult.when(
        success: (city) => expect(city, isNull),
        failure: (failure) => fail(failure.message),
      );
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
  const _FakeDeviceLocationDataSource({
    this.cityName,
    this.coordinates = const DeviceCoordinates(30.0444, 31.2357),
  });

  final String? cityName;
  final DeviceCoordinates coordinates;

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
    return coordinates;
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

DioException _badDetectCoordinatesException() {
  final options = RequestOptions(path: '/market-region/detect/');
  return DioException(
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: 400,
      data: {
        'latitude': ['Ensure that there are no more than 10 digits in total.'],
        'longitude': ['Ensure that there are no more than 10 digits in total.'],
      },
    ),
    type: DioExceptionType.badResponse,
  );
}
