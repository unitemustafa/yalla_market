import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../location/domain/services/device_location_service.dart';
import '../../domain/entities/geocoding_place.dart';

class SelectedMapLocation {
  const SelectedMapLocation({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.placeId,
  });

  final double latitude;
  final double longitude;
  final String? formattedAddress;
  final String? placeId;

  DeviceCoordinates get coordinates => DeviceCoordinates(latitude, longitude);
}

enum LocationGateStatus {
  checking,
  ready,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

class AddressLocationPickerController extends ChangeNotifier {
  AddressLocationPickerController({
    required DeviceLocationService locationDataSource,
    required DeviceCoordinates fallbackCoordinates,
    SelectedMapLocation? initialLocation,
    bool Function(DeviceCoordinates coordinates)? isWithinCoverage,
  }) : _locationDataSource = locationDataSource,
       _initialLocation = initialLocation,
       _isWithinCoverage = isWithinCoverage,
       _target = initialLocation?.coordinates ?? fallbackCoordinates,
       _formattedAddress = initialLocation?.formattedAddress,
       _placeId = initialLocation?.placeId;

  final DeviceLocationService _locationDataSource;
  final SelectedMapLocation? _initialLocation;
  final bool Function(DeviceCoordinates coordinates)? _isWithinCoverage;
  DeviceCoordinates _target;
  LocationGateStatus _gateStatus = LocationGateStatus.ready;
  bool _isLocating = false;
  bool _usesCurrentLocation = false;
  String? _errorMessage;
  String? _formattedAddress;
  String? _placeId;

  DeviceCoordinates get target => _target;
  LocationGateStatus get gateStatus => _gateStatus;
  bool get isLoading => _isLocating;
  bool get canConfirm => true;
  bool get usesCurrentLocation => _usesCurrentLocation;
  String? get errorMessage => _errorMessage;
  String? get formattedAddress => _formattedAddress;
  String? get placeId => _placeId;

  SelectedMapLocation get selectedLocation => SelectedMapLocation(
    latitude: _target.latitude,
    longitude: _target.longitude,
    formattedAddress: _formattedAddress,
    placeId: _placeId,
  );

  Future<DeviceCoordinates?> initialize() async {
    _gateStatus = LocationGateStatus.ready;
    _errorMessage = null;
    notifyListeners();
    if (_initialLocation == null) unawaited(_hydrateCurrentLocation());
    return _target;
  }

  Future<DeviceCoordinates?> useCurrentLocation() async {
    _isLocating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final coordinates = await _locationDataSource.resolveCurrentCoordinates();
      if (!isWithinCoverage(coordinates)) {
        _errorMessage = 'Your current location is outside the delivery area.';
        return null;
      }
      _target = coordinates;
      _gateStatus = LocationGateStatus.ready;
      _usesCurrentLocation = true;
      _errorMessage = null;
      _formattedAddress = null;
      _placeId = null;
      return coordinates;
    } on LocationSelectionException catch (error) {
      _setLocationFailure(error);
      return null;
    } catch (_) {
      _gateStatus = LocationGateStatus.unavailable;
      _usesCurrentLocation = false;
      _errorMessage = 'Could not find your current location. Try again.';
      return null;
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  Future<void> _hydrateCurrentLocation() async {
    final lastKnown = await _locationDataSource.resolveLastKnownCoordinates();
    if (_initialLocation == null &&
        lastKnown != null &&
        isWithinCoverage(lastKnown)) {
      _target = lastKnown;
      _usesCurrentLocation = true;
      notifyListeners();
    }
    _isLocating = true;
    notifyListeners();
    try {
      final current = await _locationDataSource.resolveCurrentCoordinates();
      if (_initialLocation == null && isWithinCoverage(current)) {
        _target = current;
        _usesCurrentLocation = true;
        _errorMessage = null;
      } else if (_initialLocation == null) {
        _errorMessage = null;
      }
    } on LocationSelectionException catch (error) {
      _setLocationFailure(error);
    } catch (_) {
      _errorMessage =
          'Could not find your current location. Choose one manually.';
    } finally {
      _gateStatus = LocationGateStatus.ready;
      _isLocating = false;
      notifyListeners();
    }
  }

  bool isWithinCoverage(DeviceCoordinates coordinates) =>
      _isWithinCoverage?.call(coordinates) ?? true;

  void selectManual(DeviceCoordinates coordinates) {
    if (!canConfirm) return;
    _target = coordinates;
    _usesCurrentLocation = false;
    _errorMessage = null;
    _formattedAddress = null;
    _placeId = null;
    notifyListeners();
  }

  void selectSearchResult(GeocodingPlace place) {
    if (!canConfirm) return;
    _target = DeviceCoordinates(place.latitude, place.longitude);
    _usesCurrentLocation = false;
    _errorMessage = null;
    _formattedAddress = place.formattedAddress;
    _placeId = place.placeId;
    notifyListeners();
  }

  void applyReverseResult(
    DeviceCoordinates requestedCoordinates,
    GeocodingPlace? place,
  ) {
    if (!_sameCoordinates(_target, requestedCoordinates)) return;
    _formattedAddress = place?.formattedAddress;
    _placeId = place?.placeId;
    notifyListeners();
  }

  Future<void> openRequiredSettings() {
    return switch (_gateStatus) {
      LocationGateStatus.permissionDeniedForever =>
        _locationDataSource.openAppSettings(),
      LocationGateStatus.serviceDisabled =>
        _locationDataSource.openLocationSettings(),
      _ => Future<void>.value(),
    };
  }

  void _setLocationFailure(LocationSelectionException error) {
    _usesCurrentLocation = false;
    _errorMessage = error.message;
    _gateStatus = LocationGateStatus.ready;
  }

  bool _sameCoordinates(DeviceCoordinates first, DeviceCoordinates second) =>
      (first.latitude - second.latitude).abs() < 0.0000001 &&
      (first.longitude - second.longitude).abs() < 0.0000001;
}
