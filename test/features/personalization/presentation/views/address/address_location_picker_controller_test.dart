import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/location/data/datasources/device_location_data_source.dart';
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
      expect(controller.gateStatus, LocationGateStatus.ready);

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
