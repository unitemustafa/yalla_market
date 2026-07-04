import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/home/presentation/views/home_view.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';

void main() {
  testWidgets('home region label does not show general for null', (
    tester,
  ) async {
    late String label;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            label = homeRegionLabel(context, null);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(label, isEmpty);
  });

  testWidgets('home region label shows general only for explicit general', (
    tester,
  ) async {
    late String label;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            label = homeRegionLabel(context, CityData.general);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(label, 'General');
  });

  testWidgets('home region label shows backend service city name', (
    tester,
  ) async {
    late String label;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            label = homeRegionLabel(
              context,
              const CityData(name: 'الجزائر', slug: '1', serviceCityId: 1),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(label, 'الجزائر');
  });
}
