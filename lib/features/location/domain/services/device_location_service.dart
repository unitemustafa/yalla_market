abstract interface class DeviceLocationService {
  Future<String?> resolveCurrentCityName({bool requestPermission = true});

  Future<DeviceCoordinates> resolveCurrentCoordinates({
    bool requestPermission = true,
  });

  Future<DeviceCoordinates?> resolveLastKnownCoordinates({
    bool requestPermission = false,
  });

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}

enum LocationSelectionFailure {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  positionUnavailable,
  unknown,
}

class LocationSelectionException implements Exception {
  const LocationSelectionException(
    this.message, {
    this.reason = LocationSelectionFailure.unknown,
  });

  final String message;
  final LocationSelectionFailure reason;

  @override
  String toString() => message;
}

class DeviceCoordinates {
  const DeviceCoordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
