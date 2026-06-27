import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/city_data.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/device_location_data_source.dart';
import '../datasources/location_preferences.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(
    this._preferences,
    this._deviceLocation, [
    this._apiClient,
  ]);

  final LocationPreferences _preferences;
  final DeviceLocationDataSource _deviceLocation;
  final ApiClient? _apiClient;

  @override
  Future<ApiResult<List<CityData>>> getAvailableCities() async {
    if (_apiClient == null) {
      return ApiResult.success(
        CityData.supported.where((city) => !city.isGeneral).toList(),
      );
    }
    try {
      return ApiResult.success(await _fetchAvailableCities());
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load available cities.'),
      );
    }
  }

  @override
  Future<ApiResult<CityData?>> getSelectedCity() async {
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

      if (_apiClient != null && slug != null && slug.trim().isNotEmpty) {
        try {
          final availableCities = await _fetchAvailableCities();
          for (final city in availableCities) {
            if (city.slug == slug.trim().toLowerCase()) {
              return ApiResult.success(city.withSource(source));
            }
          }
          return const ApiResult.success(CityData.general);
        } catch (_) {
          // Keep the locally saved choice while the API is temporarily offline.
        }
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

  Future<List<CityData>> _fetchAvailableCities() async {
    final payload = await _apiClient!.get<List<dynamic>>('/locations/cities/');
    return payload
        .whereType<Map>()
        .map((item) => CityData.fromJson(Map<String, dynamic>.from(item)))
        .where((city) => city.name.isNotEmpty && city.slug.isNotEmpty)
        .toList(growable: false);
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
    try {
      final savedCity = city;
      await _preferences.setSelectedCity(
        savedCity.slug,
        savedCity.name,
        source: savedCity.source.storageValue,
      );
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
    if (_apiClient != null) {
      final coordinates = await _deviceLocation.resolveCurrentCoordinates(
        requestPermission: requestPermission,
      );
      final payload = await _apiClient.post<Map<String, dynamic>>(
        '/locations/resolve/',
        data: {
          'latitude': coordinates.latitude,
          'longitude': coordinates.longitude,
        },
      );
      final cityPayload = payload['city'];
      if (cityPayload is Map) {
        return CityData.fromJson(
          Map<String, dynamic>.from(cityPayload),
        ).withSource(RegionSource.gps);
      }
      final displayName = payload['display_name'] as String?;
      return CityData(
        name: displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : CityData.general.name,
        slug: CityData.generalSlug,
        source: RegionSource.general,
      );
    }
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
