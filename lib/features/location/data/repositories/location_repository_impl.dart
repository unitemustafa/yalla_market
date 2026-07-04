import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/city_data.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/device_location_data_source.dart';
import '../datasources/location_preferences.dart';

class LocationRepositoryImpl implements LocationRepository, LocationUserScope {
  const LocationRepositoryImpl(
    this._preferences,
    this._deviceLocation, [
    this._apiClient,
  ]);

  final LocationPreferences _preferences;
  final DeviceLocationDataSource _deviceLocation;
  final ApiClient? _apiClient;

  @override
  Future<ApiResult<void>> activateUser(String userId) async {
    try {
      await _preferences.activateUser(userId);
      return const ApiResult.success(null);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load your saved city.'),
      );
    }
  }

  @override
  Future<ApiResult<List<CityData>>> getAvailableCities() async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      return ApiResult.success(CityData.dashboardRegions);
    }
    try {
      final payload = await apiClient.get<Map<String, dynamic>>(
        '/market-region/options/',
      );
      final response = RegionOptionsResponse.fromJson(payload);
      if (response.currentSelection != null) {
        await _cacheSelectedCity(response.currentSelection!.city);
      }
      return ApiResult.success(response.options);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load available regions.'),
      );
    }
  }

  @override
  Future<ApiResult<CityData?>> getSelectedCity() async {
    final apiClient = _apiClient;
    if (apiClient == null) return _getCachedSelectedCity();
    try {
      final payload = await apiClient.get<Map<String, dynamic>>(
        '/market-region/me/',
      );
      final current = payload['current_selection'];
      if (current is! Map<String, dynamic>) {
        await _preferences.clearSelectedCity();
        return const ApiResult.success(null);
      }
      final selection = RegionSelection.fromJson(current);
      await _cacheSelectedCity(selection.city);
      return ApiResult.success(selection.city);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load your selected city.'),
      );
    }
  }

  Future<ApiResult<CityData?>> _getCachedSelectedCity() async {
    try {
      final slug = await _preferences.getSelectedCitySlug();
      final source = RegionSource.fromString(
        await _preferences.getSelectedRegionSource(),
      );
      final customName = await _preferences.getSelectedCityName();
      final supportedCity = CityData.fromSlug(slug);
      if (supportedCity != null) {
        if (supportedCity.isGeneral &&
            customName != null &&
            customName.trim().isNotEmpty &&
            customName.trim() != CityData.general.name) {
          return ApiResult.success(
            CityData(
              name: customName.trim(),
              slug: CityData.generalSlug,
              source: RegionSource.general,
            ),
          );
        }
        return ApiResult.success(supportedCity.withSource(source));
      }

      if (slug == null || customName == null || customName.trim().isEmpty) {
        return const ApiResult.success(null);
      }

      return ApiResult.success(
        CityData(name: customName.trim(), slug: slug, source: source),
      );
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load your selected city.'),
      );
    }
  }

  @override
  Future<ApiResult<bool>> hasSeenCitySelection() async {
    try {
      return ApiResult.success(await _preferences.hasSeenCitySelection());
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load your city selection status.'),
      );
    }
  }

  @override
  Future<ApiResult<void>> markCitySelectionSeen() async {
    try {
      await _preferences.markCitySelectionSeen();
      return const ApiResult.success(null);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not save your city selection status.'),
      );
    }
  }

  @override
  Future<ApiResult<void>> clearSelectedCity() async {
    try {
      await _preferences.clearSelectedCity();
      return const ApiResult.success(null);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not reset your selected city.'),
      );
    }
  }

  @override
  Future<ApiResult<CityData>> saveSelectedCity(CityData city) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      try {
        await _cacheSelectedCity(city);
        return ApiResult.success(city);
      } catch (_) {
        return const ApiResult.failure(
          UnknownFailure('Could not save your selected city.'),
        );
      }
    }
    try {
      final data = city.toMarketRegionPatchJson();
      if (data['mode'] == 'service_city' && data['service_city_id'] == null) {
        return const ApiResult.failure(
          ValidationFailure('Choose a valid service city.'),
        );
      }

      final payload = await apiClient.patch<Map<String, dynamic>>(
        '/market-region/me/',
        data: data,
      );
      final current = payload['current_selection'];
      final savedCity = current is Map<String, dynamic>
          ? RegionSelection.fromJson(current).city.withSource(city.source)
          : city;
      await _cacheSelectedCity(savedCity);
      return ApiResult.success(savedCity);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not save your selected city.'),
      );
    }
  }

  @override
  Future<ApiResult<CityData>> detectCurrentLocation({
    bool requestPermission = true,
  }) async {
    try {
      return ApiResult.success(
        await _cityFromCurrentLocation(requestPermission: requestPermission),
      );
    } on LocationSelectionException catch (error) {
      return ApiResult.failure(ValidationFailure(error.message));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not use your current location.'),
      );
    }
  }

  Future<ApiResult<GpsRegionDetection>> detectMarketRegion() async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      return const ApiResult.failure(
        UnknownFailure('Could not check your current location.'),
      );
    }
    try {
      final coordinates = await _deviceLocation.resolveCurrentCoordinates();
      final latitude = _roundCoordinate(coordinates.latitude);
      final longitude = _roundCoordinate(coordinates.longitude);
      final payload = await apiClient.post<Map<String, dynamic>>(
        '/market-region/detect/',
        data: {'latitude': latitude, 'longitude': longitude},
      );
      return ApiResult.success(GpsRegionDetection.fromJson(payload));
    } on LocationSelectionException catch (error) {
      return ApiResult.failure(ValidationFailure(error.message));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not check your current location.'),
      );
    }
  }

  @override
  Future<ApiResult<CityData>> useCurrentLocation() async {
    try {
      final city = await _cityFromCurrentLocation();

      await _preferences.setSelectedCity(
        city.slug,
        city.name,
        source: city.source.storageValue,
      );
      return ApiResult.success(city);
    } on LocationSelectionException catch (error) {
      return ApiResult.failure(ValidationFailure(error.message));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not use your current location.'),
      );
    }
  }

  Future<CityData> _cityFromCurrentLocation({
    bool requestPermission = true,
  }) async {
    final cityName = await _deviceLocation.resolveCurrentCityName(
      requestPermission: requestPermission,
    );
    final resolvedName = cityName?.trim();
    final city =
        CityData.fromName(resolvedName) ??
        (resolvedName == null || resolvedName.isEmpty
            ? CityData.general
            : CityData(
                name: resolvedName,
                slug: CityData.generalSlug,
                source: RegionSource.general,
              ));
    final source = city.isGeneral ? RegionSource.general : RegionSource.gps;
    return city.withSource(source);
  }

  Future<void> _cacheSelectedCity(CityData city) {
    return _preferences.setSelectedCity(
      city.slug,
      city.name,
      source: city.source.storageValue,
    );
  }

  double _roundCoordinate(double value) {
    return double.parse(value.toStringAsFixed(7));
  }

  @override
  Future<ApiResult<void>> openAppSettings() async {
    try {
      await _deviceLocation.openAppSettings();
      return const ApiResult.success(null);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not open app settings.'),
      );
    }
  }

  @override
  Future<ApiResult<void>> openLocationSettings() async {
    try {
      await _deviceLocation.openLocationSettings();
      return const ApiResult.success(null);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not open location settings.'),
      );
    }
  }
}
