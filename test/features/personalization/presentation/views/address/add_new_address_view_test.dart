import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/location/data/datasources/device_location_data_source.dart';
import 'package:yalla_market/features/personalization/presentation/views/address/add_new_address_view.dart';

void main() {
  testWidgets('does not save a new address when GPS access fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AddNewAddressView(
          locationDataSource: _FailingLocationDataSource(),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(6));
    await tester.enterText(fields.at(0), 'Mustafa Ali');
    await tester.enterText(fields.at(1), '01000000000');
    await tester.enterText(fields.at(2), '12 Tahrir St');
    await tester.enterText(fields.at(3), 'Cairo');
    await tester.enterText(fields.at(4), 'Cairo');
    await tester.enterText(fields.at(5), 'Egypt');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Location required'), findsOneWidget);
    expect(
      find.text(
        'Location permission was not granted. Allow location to continue.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add Address'), findsOneWidget);
  });
}

class _FailingLocationDataSource implements DeviceLocationDataSource {
  const _FailingLocationDataSource();

  @override
  Future<DeviceCoordinates> resolveCurrentCoordinates({
    bool requestPermission = true,
  }) {
    throw const LocationSelectionException(
      'Location permission was not granted. Allow location to continue.',
    );
  }

  @override
  Future<String?> resolveCurrentCityName({
    bool requestPermission = true,
  }) async {
    return null;
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}
