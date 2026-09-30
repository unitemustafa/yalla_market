import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/location/data/datasources/device_location_data_source.dart';
import 'package:yalla_market/features/personalization/domain/entities/geocoding_place.dart';
import 'package:yalla_market/features/personalization/presentation/views/address/address_location_picker_view.dart';

void main() {
  const fallback = DeviceCoordinates(30.0444, 31.2357);

  test('shows fallback immediately then applies current GPS', () async {
    final source = _FakeLocationDataSource(
      results: [const DeviceCoordinates(30.1234567, 31.7654321)],
    );
    final controller = AddressLocationPickerController(
      locationDataSource: source,
      fallbackCoordinates: fallback,
    );

    final result = await controller.initialize();

    expect(result?.latitude, fallback.latitude);
    expect(controller.canConfirm, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(controller.target.longitude, 31.7654321);
    expect(controller.canConfirm, isTrue);
    expect(controller.usesCurrentLocation, isTrue);
    expect(controller.errorMessage, isNull);
  });

  test(
    'keeps manual map selection available when permission is unavailable',
    () async {
      final source = _FakeLocationDataSource(
        results: [
          const LocationSelectionException(
            'Location permission denied.',
            reason: LocationSelectionFailure.permissionDeniedForever,
          ),
        ],
      );
      final controller = AddressLocationPickerController(
        locationDataSource: source,
        fallbackCoordinates: fallback,
      );

      await controller.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(controller.target, same(fallback));
      expect(controller.canConfirm, isTrue);
      expect(controller.usesCurrentLocation, isFalse);
      expect(controller.errorMessage, 'Location permission denied.');
      expect(controller.gateStatus, LocationGateStatus.permissionDeniedForever);
      await controller.openRequiredSettings();
      expect(source.openedAppSettings, isTrue);

      controller.selectManual(const DeviceCoordinates(29.99, 31.11));

      expect(controller.canConfirm, isTrue);
      expect(controller.usesCurrentLocation, isFalse);
      expect(controller.target.latitude, 29.99);
    },
  );

  test(
    'editing starts from saved coordinates after the GPS gate passes',
    () async {
      final source = _FakeLocationDataSource(
        results: [const DeviceCoordinates(30.5, 31.5)],
      );
      final controller = AddressLocationPickerController(
        locationDataSource: source,
        fallbackCoordinates: fallback,
        initialLocation: const SelectedMapLocation(
          latitude: 29.9,
          longitude: 31.1,
          formattedAddress: 'Saved address',
          placeId: 'saved-id',
        ),
      );

      await controller.initialize();

      expect(controller.canConfirm, isTrue);
      expect(controller.target.latitude, 29.9);
      expect(controller.target.longitude, 31.1);
      expect(controller.formattedAddress, 'Saved address');
      expect(controller.usesCurrentLocation, isFalse);
    },
  );

  test('can retry GPS after a failure', () async {
    final source = _FakeLocationDataSource(
      results: [
        const LocationSelectionException('GPS is disabled.'),
        const DeviceCoordinates(30.5, 31.5),
      ],
    );
    final controller = AddressLocationPickerController(
      locationDataSource: source,
      fallbackCoordinates: fallback,
    );

    await controller.initialize();
    await Future<void>.delayed(Duration.zero);
    expect(controller.canConfirm, isTrue);

    final result = await controller.useCurrentLocation();

    expect(result?.latitude, 30.5);
    expect(controller.canConfirm, isTrue);
    expect(controller.usesCurrentLocation, isTrue);
    expect(controller.errorMessage, isNull);
  });

  test('GPS errors do not replace the selected city fallback', () async {
    final source = _FakeLocationDataSource(
      results: [
        const LocationSelectionException(
          'GPS disabled.',
          reason: LocationSelectionFailure.serviceDisabled,
        ),
      ],
    );
    final controller = AddressLocationPickerController(
      locationDataSource: source,
      fallbackCoordinates: fallback,
    );

    await controller.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(controller.canConfirm, isTrue);
    expect(controller.target, same(fallback));
    expect(controller.errorMessage, 'GPS disabled.');
    expect(controller.gateStatus, LocationGateStatus.serviceDisabled);
    await controller.openRequiredSettings();
    expect(source.openedLocationSettings, isTrue);
  });

  test('GPS outside the selected city never replaces its center', () async {
    final source = _FakeLocationDataSource(
      results: [const DeviceCoordinates(30.5877, 31.5020)],
    );
    final controller = AddressLocationPickerController(
      locationDataSource: source,
      fallbackCoordinates: fallback,
      isWithinCoverage: (coordinates) =>
          (coordinates.latitude - fallback.latitude).abs() < 0.2 &&
          (coordinates.longitude - fallback.longitude).abs() < 0.2,
    );

    await controller.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(controller.target, same(fallback));
    expect(controller.usesCurrentLocation, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('late GPS result does not replace a manual map selection', () async {
    final source = _DeferredLocationDataSource();
    final controller = AddressLocationPickerController(
      locationDataSource: source,
      fallbackCoordinates: fallback,
    );
    await controller.initialize();
    source.lastKnown.complete(null);
    await Future<void>.delayed(Duration.zero);

    const manual = DeviceCoordinates(30.1, 31.1);
    controller.selectManual(manual);
    source.current.complete(const DeviceCoordinates(30.2, 31.2));
    await Future<void>.delayed(Duration.zero);

    expect(controller.target, same(manual));
    expect(controller.usesCurrentLocation, isFalse);
    controller.dispose();
  });

  test('late last known position does not replace a search result', () async {
    final source = _DeferredLocationDataSource();
    final controller = AddressLocationPickerController(
      locationDataSource: source,
      fallbackCoordinates: fallback,
    );
    await controller.initialize();
    controller.selectSearchResult(
      const GeocodingPlace(
        latitude: 30.3,
        longitude: 31.3,
        formattedAddress: 'Selected place',
      ),
    );
    source.lastKnown.complete(const DeviceCoordinates(30.2, 31.2));
    await Future<void>.delayed(Duration.zero);

    expect(controller.target.latitude, 30.3);
    expect(controller.formattedAddress, 'Selected place');
    expect(source.currentRequested, isFalse);
    controller.dispose();
  });

  test(
    'closing picker while GPS is pending does not notify after dispose',
    () async {
      final source = _DeferredLocationDataSource();
      final controller = AddressLocationPickerController(
        locationDataSource: source,
        fallbackCoordinates: fallback,
      );
      await controller.initialize();
      controller.dispose();
      source.lastKnown.complete(null);
      await Future<void>.delayed(Duration.zero);
      expect(source.currentRequested, isFalse);
    },
  );
}

class _DeferredLocationDataSource implements DeviceLocationDataSource {
  final lastKnown = Completer<DeviceCoordinates?>();
  final current = Completer<DeviceCoordinates>();
  bool currentRequested = false;

  @override
  Future<DeviceCoordinates?> resolveLastKnownCoordinates({
    bool requestPermission = false,
  }) => lastKnown.future;

  @override
  Future<DeviceCoordinates> resolveCurrentCoordinates({
    bool requestPermission = true,
  }) {
    currentRequested = true;
    return current.future;
  }

  @override
  Future<String?> resolveCurrentCityName({
    bool requestPermission = true,
  }) async => null;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

class _FakeLocationDataSource implements DeviceLocationDataSource {
  _FakeLocationDataSource({required this.results});

  final List<Object> results;
  int _index = 0;
  bool openedAppSettings = false;
  bool openedLocationSettings = false;

  @override
  Future<DeviceCoordinates?> resolveLastKnownCoordinates({
    bool requestPermission = false,
  }) async {
    return null;
  }

  @override
  Future<DeviceCoordinates> resolveCurrentCoordinates({
    bool requestPermission = true,
  }) async {
    final result = results[_index++];
    if (result is DeviceCoordinates) return result;
    throw result;
  }

  @override
  Future<String?> resolveCurrentCityName({
    bool requestPermission = true,
  }) async {
    return null;
  }

  @override
  Future<void> openAppSettings() async {
    openedAppSettings = true;
  }

  @override
  Future<void> openLocationSettings() async {
    openedLocationSettings = true;
  }
}
