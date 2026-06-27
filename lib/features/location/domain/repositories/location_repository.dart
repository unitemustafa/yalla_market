import '../../../../core/network/api_result.dart';
import '../entities/city_data.dart';

abstract class LocationRepository {
  Future<ApiResult<List<CityData>>> getAvailableCities() {
    throw UnimplementedError();
  }

  Future<ApiResult<CityData?>> getSelectedCity();

  Future<ApiResult<bool>> hasSeenCitySelection() {
    throw UnimplementedError();
  }

  Future<ApiResult<void>> markCitySelectionSeen() {
    throw UnimplementedError();
  }

  Future<ApiResult<void>> clearSelectedCity() {
    throw UnimplementedError();
  }

  Future<ApiResult<CityData>> saveSelectedCity(CityData city);

  Future<ApiResult<CityData>> detectCurrentLocation({
    bool requestPermission = true,
  }) {
    throw UnimplementedError();
  }

  Future<ApiResult<CityData>> useCurrentLocation();

  Future<ApiResult<void>> openAppSettings() {
    throw UnimplementedError();
  }

  Future<ApiResult<void>> openLocationSettings() {
    throw UnimplementedError();
  }
}
