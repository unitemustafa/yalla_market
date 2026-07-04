import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/location/domain/repositories/location_repository.dart';
import 'package:yalla_market/features/location/domain/usecases/location_usecases.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';

void main() {
  group('LocationCubit region GPS session flow', () {
    test('runs GPS suggestion only once per session', () {
      final cubit = LocationCubit(_useCases(_FakeLocationRepository()));

      expect(cubit.consumeGpsSuggestionSlot(), isTrue);
      expect(cubit.consumeGpsSuggestionSlot(), isFalse);

      cubit.clearSession();

      expect(cubit.consumeGpsSuggestionSlot(), isTrue);
    });

    test('tracks dismissed suggestions for the current session', () {
      final cubit = LocationCubit(_useCases(_FakeLocationRepository()));
      const current = CityData(name: 'Cairo', slug: '1', serviceCityId: 1);
      const detected = CityData(name: 'Giza', slug: '2', serviceCityId: 2);

      expect(cubit.wasSuggestionDismissed(current, detected), isFalse);

      cubit.markSuggestionDismissed(current, detected);

      expect(cubit.wasSuggestionDismissed(current, detected), isTrue);
    });

    test(
      'parses backend GPS suggestion without changing region state',
      () async {
        final repository = _FakeLocationRepository(
          detection: const GpsRegionDetection(
            action: GpsRegionAction.suggestSwitch,
            currentSelection: RegionSelection(
              mode: RegionMode.serviceCity,
              city: CityData(name: 'Cairo', slug: '1', serviceCityId: 1),
            ),
            detectedRegion: RegionSelection(
              mode: RegionMode.serviceCity,
              city: CityData(name: 'Giza', slug: '2', serviceCityId: 2),
            ),
            message: 'Switch?',
          ),
        );
        final cubit = LocationCubit(_useCases(repository));
        cubit.syncCity(
          const CityData(name: 'Cairo', slug: '1', serviceCityId: 1),
        );

        final detection = await cubit.detectMarketRegionSuggestion();

        expect(detection?.action, GpsRegionAction.suggestSwitch);
        expect(cubit.state.selectedCity?.serviceCityId, 1);
      },
    );

    test(
      'detect failure keeps current region and never becomes general',
      () async {
        final repository = _FakeLocationRepository(failDetection: true);
        final cubit = LocationCubit(_useCases(repository));
        cubit.syncCity(
          const CityData(name: 'الجزائر', slug: '1', serviceCityId: 1),
        );

        final detection = await cubit.detectMarketRegionSuggestion();

        expect(detection, isNull);
        expect(cubit.state.selectedCity?.name, 'الجزائر');
        expect(cubit.state.selectedCity?.isGeneral, isFalse);
      },
    );

    test('current region load failure does not reuse cached general', () async {
      final repository = _FakeLocationRepository(failSelectedCity: true);
      final cubit = LocationCubit(_useCases(repository));
      cubit.syncCity(CityData.general);

      final city = await cubit.loadSelectedCity();

      expect(city, isNull);
      expect(cubit.state.selectedCity, isNull);
    });
  });
}

LocationUseCases _useCases(_FakeLocationRepository repository) {
  return LocationUseCases(
    activateUser: ActivateLocationUserUseCase(repository),
    getAvailableCities: GetAvailableCitiesUseCase(repository),
    getSelectedCity: GetSelectedCityUseCase(repository),
    hasSeenCitySelection: HasSeenCitySelectionUseCase(repository),
    markCitySelectionSeen: MarkCitySelectionSeenUseCase(repository),
    clearSelectedCity: ClearSelectedCityUseCase(repository),
    saveSelectedCity: SaveSelectedCityUseCase(repository),
    detectCurrentLocation: DetectCurrentLocationUseCase(repository),
    detectMarketRegion: DetectMarketRegionUseCase(repository),
    useCurrentLocation: UseCurrentLocationUseCase(repository),
    openAppSettings: OpenLocationAppSettingsUseCase(repository),
    openLocationSettings: OpenDeviceLocationSettingsUseCase(repository),
  );
}

class _FakeLocationRepository implements LocationRepository, LocationUserScope {
  const _FakeLocationRepository({
    this.detection,
    this.failDetection = false,
    this.failSelectedCity = false,
  });

  final GpsRegionDetection? detection;
  final bool failDetection;
  final bool failSelectedCity;

  @override
  Future<ApiResult<void>> activateUser(String userId) async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> clearSelectedCity() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<CityData>> detectCurrentLocation({
    bool requestPermission = true,
  }) async {
    return const ApiResult.success(
      CityData(name: 'Cairo', slug: '1', serviceCityId: 1),
    );
  }

  Future<ApiResult<GpsRegionDetection>> detectMarketRegion() async {
    if (failDetection) {
      return const ApiResult.failure(
        ValidationFailure('Ensure that there are no more than 10 digits.'),
      );
    }
    return ApiResult.success(
      detection ??
          const GpsRegionDetection(
            action: GpsRegionAction.sameRegion,
            currentSelection: null,
            detectedRegion: null,
            message: '',
          ),
    );
  }

  @override
  Future<ApiResult<List<CityData>>> getAvailableCities() async {
    return const ApiResult.success([
      CityData(name: 'Cairo', slug: '1', serviceCityId: 1),
    ]);
  }

  @override
  Future<ApiResult<CityData?>> getSelectedCity() async {
    if (failSelectedCity) {
      return const ApiResult.failure(
        UnknownFailure('Could not load your selected city.'),
      );
    }
    return const ApiResult.success(
      CityData(name: 'Cairo', slug: '1', serviceCityId: 1),
    );
  }

  @override
  Future<ApiResult<bool>> hasSeenCitySelection() async {
    return const ApiResult.success(false);
  }

  @override
  Future<ApiResult<void>> markCitySelectionSeen() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> openAppSettings() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> openLocationSettings() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<CityData>> saveSelectedCity(CityData city) async {
    return ApiResult.success(city);
  }

  @override
  Future<ApiResult<CityData>> useCurrentLocation() async {
    return const ApiResult.success(
      CityData(name: 'Cairo', slug: '1', serviceCityId: 1),
    );
  }
}
