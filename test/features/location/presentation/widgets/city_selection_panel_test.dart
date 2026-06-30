import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_state.dart';
import 'package:yalla_market/features/location/presentation/widgets/city_selection_panel.dart';

void main() {
  testWidgets('manual mode shows cities and other general region', (
    tester,
  ) async {
    CityData? selectedCity;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CitySelectionPanel(
              state: const LocationReady(null, [
                CityData(name: 'Cairo', slug: 'cairo'),
                CityData(name: 'Sharm El Sheikh', slug: 'sharm-el-sheikh'),
              ]),
              compact: true,
              onCitySelected: (city) => selectedCity = city,
              onUseCurrentLocation: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Use GPS location'), findsOneWidget);

    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();

    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text('Sharm El Sheikh'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();

    expect(selectedCity?.name, 'General');
    expect(selectedCity?.slug, CityData.generalSlug);
  });

  testWidgets('automatic mode exposes GPS action', (tester) async {
    var usedCurrentLocation = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CitySelectionPanel(
              state: const LocationReady(null),
              compact: true,
              onCitySelected: (_) {},
              onUseCurrentLocation: () => usedCurrentLocation = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Use GPS location'), findsOneWidget);

    await tester.tap(find.text('Use GPS location'));
    await tester.pumpAndSettle();

    expect(usedCurrentLocation, isTrue);
  });

  testWidgets('manual-only mode shows cities without requesting GPS', (
    tester,
  ) async {
    var usedCurrentLocation = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CitySelectionPanel(
              state: const LocationReady(null, [
                CityData(name: 'Cairo', slug: 'cairo'),
              ]),
              manualOnly: true,
              initialMode: LocationChoiceMode.manual,
              onCitySelected: (_) {},
              onUseCurrentLocation: () => usedCurrentLocation = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Automatic'), findsNothing);
    expect(find.text('Use GPS location'), findsNothing);
    expect(usedCurrentLocation, isFalse);
  });

  testWidgets('manual mode stays locked until GPS is verified', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CitySelectionPanel(
            state: const LocationReady(null, [
              CityData(name: 'Cairo', slug: 'cairo'),
            ]),
            manualEnabled: false,
            onCitySelected: (_) {},
            onUseCurrentLocation: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();

    expect(find.text('Use GPS location'), findsOneWidget);
    expect(find.text('Cairo'), findsNothing);
    expect(find.text('Other'), findsNothing);
  });
}
