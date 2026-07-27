import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/location/data/datasources/device_location_data_source.dart';
import 'package:yalla_market/features/personalization/data/datasources/geoapify_geocoding_data_source.dart';
import 'package:yalla_market/features/personalization/presentation/views/address/address_location_picker_view.dart';

void main() {
  testWidgets('debounces search and ignores an older response', (tester) async {
    final geocoding = _FakeGeocodingDataSource();
    await tester.pumpWidget(_picker(geocoding: geocoding));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final search = find.byType(TextField);
    await tester.enterText(search, 'Ca');
    await tester.pump(const Duration(milliseconds: 600));
    expect(geocoding.searches, isEmpty);

    await tester.enterText(search, 'Cairo');
    await tester.pump(const Duration(milliseconds: 500));
    expect(geocoding.searches, ['Cairo']);

    await tester.enterText(search, 'Giza');
    await tester.pump(const Duration(milliseconds: 500));
    expect(geocoding.searches, ['Cairo', 'Giza']);

    geocoding.completeSearch('Giza', const [
      GeoapifyPlace(
        addressLine1: 'Giza result',
        latitude: 30.01,
        longitude: 31.2,
      ),
    ]);
    await tester.pump();
    expect(find.text('Giza result'), findsOneWidget);

    geocoding.completeSearch('Cairo', const [
      GeoapifyPlace(
        addressLine1: 'Old Cairo result',
        latitude: 30.04,
        longitude: 31.23,
      ),
    ]);
    await tester.pump();

    expect(find.text('Giza result'), findsOneWidget);
    expect(find.text('Old Cairo result'), findsNothing);
  });

  testWidgets('reverse-geocoding failure keeps confirmation enabled', (
    tester,
  ) async {
    final geocoding = _FakeGeocodingDataSource(reverseFails: true);
    await tester.pumpWidget(_picker(geocoding: geocoding));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(
      find.text('Address lookup failed. You can still continue.'),
      findsOneWidget,
    );
    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Continue with this location'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });
}

Widget _picker({required MapGeocodingDataSource geocoding}) {
  return MaterialApp(
    home: AddressLocationPickerView(
      locationDataSource: const _ReadyLocationDataSource(),
      geocodingDataSource: geocoding,
      fallbackCoordinates: const DeviceCoordinates(30.0444, 31.2357),
      tileUrlTemplateOverride: 'https://127.0.0.1:1/{z}/{x}/{y}.png',
    ),
  );
}

class _ReadyLocationDataSource implements DeviceLocationDataSource {
  const _ReadyLocationDataSource();

  @override
  Future<DeviceCoordinates> resolveCurrentCoordinates({
    bool requestPermission = true,
  }) async {
    return const DeviceCoordinates(30.0444, 31.2357);
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

class _FakeGeocodingDataSource implements MapGeocodingDataSource {
  _FakeGeocodingDataSource({this.reverseFails = false});

  final bool reverseFails;
  final List<String> searches = [];
  final Map<String, Completer<List<GeoapifyPlace>>> _pending = {};

  @override
  Future<List<GeoapifyPlace>> autocomplete({
    required String query,
    required double latitude,
    required double longitude,
    required String language,
  }) {
    searches.add(query);
    final completer = Completer<List<GeoapifyPlace>>();
    _pending[query] = completer;
    return completer.future;
  }

  void completeSearch(String query, List<GeoapifyPlace> results) {
    _pending[query]!.complete(results);
  }

  @override
  Future<GeoapifyPlace?> reverse({
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    if (reverseFails) throw StateError('offline');
    return null;
  }
}
