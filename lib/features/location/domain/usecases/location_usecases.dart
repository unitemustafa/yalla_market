import '../../../../core/network/api_result.dart';
import '../entities/city_data.dart';
import '../repositories/location_repository.dart';

class ActivateLocationUserUseCase {
  const ActivateLocationUserUseCase(this._repository);

  final LocationUserScope _repository;

  Future<ApiResult<void>> call(String userId) {
    return _repository.activateUser(userId);
  }
}

class GetAvailableCitiesUseCase {
  const GetAvailableCitiesUseCase(this._repository);

  final LocationRepository _repository;

  Future<ApiResult<List<CityData>>> call() => _repository.getAvailableCities();
}

class GetSelectedCityUseCase {
  const GetSelectedCityUseCase(this._repository);

  final LocationRepository _repository;

  Future<ApiResult<CityData?>> call() {
    return _repository.getSelectedCity();
  }
}

class HasSeenCitySelectionUseCase {
  const HasSeenCitySelectionUseCase(this._repository);

  final LocationRepository _repository;

  Future<ApiResult<bool>> call() {
    return _repository.hasSeenCitySelection();
  }
}

class MarkCitySelectionSeenUseCase {
  const MarkCitySelectionSeenUseCase(this._repository);

  final LocationRepository _repository;

  Future<ApiResult<void>> call() {
    return _repository.markCitySelectionSeen();
  }
}

class ClearSelectedCityUseCase {
  const ClearSelectedCityUseCase(this._repository);

  final LocationRepository _repository;

  Future<ApiResult<void>> call() {
    return _repository.clearSelectedCity();
  }
}

class SaveSelectedCityUseCase {
  const SaveSelectedCityUseCase(this._repository);

  final LocationRepository _repository;

  Future<ApiResult<CityData>> call(
    CityData city, {
    RegionSource source = RegionSource.manual,
  }) {
    return _repository.saveSelectedCity(city.withSource(source));
  }
}

class UseCurrentLocationUseCase {
  const UseCurrentLocationUseCase(this._repository);

  final LocationRepository _repository;

  Future<ApiResult<CityData>> call() {
    return _repository.useCurrentLocation();
  }
}

class DetectCurrentLocationUseCase {
  const DetectCurrentLocationUseCase(this._repository);

  final LocationRepository _repository;

  Future<ApiResult<CityData>> call({bool requestPermission = true}) {
    return _repository.detectCurrentLocation(
      requestPermission: requestPermission,
    );
  }
}

class OpenLocationAppSettingsUseCase {
  const OpenLocationAppSettingsUseCase(this._repository);

  final LocationRepository _repository;

  Future<ApiResult<void>> call() {
    return _repository.openAppSettings();
  }
}

class OpenDeviceLocationSettingsUseCase {
  const OpenDeviceLocationSettingsUseCase(this._repository);

  final LocationRepository _repository;

  Future<ApiResult<void>> call() {
    return _repository.openLocationSettings();
  }
}

class LocationUseCases {
  const LocationUseCases({
    required this.activateUser,
    required this.getAvailableCities,
    required this.getSelectedCity,
    required this.hasSeenCitySelection,
    required this.markCitySelectionSeen,
    required this.clearSelectedCity,
    required this.saveSelectedCity,
    required this.detectCurrentLocation,
    required this.useCurrentLocation,
    required this.openAppSettings,
    required this.openLocationSettings,
  });

  final ActivateLocationUserUseCase activateUser;

  final GetAvailableCitiesUseCase getAvailableCities;

  final GetSelectedCityUseCase getSelectedCity;
  final HasSeenCitySelectionUseCase hasSeenCitySelection;
  final MarkCitySelectionSeenUseCase markCitySelectionSeen;
  final ClearSelectedCityUseCase clearSelectedCity;
  final SaveSelectedCityUseCase saveSelectedCity;
  final DetectCurrentLocationUseCase detectCurrentLocation;
  final UseCurrentLocationUseCase useCurrentLocation;
  final OpenLocationAppSettingsUseCase openAppSettings;
  final OpenDeviceLocationSettingsUseCase openLocationSettings;
}
