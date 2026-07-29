import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/location/domain/utils/geo_coverage.dart';

void main() {
  test('uses a configured radius for city coverage', () {
    expect(
      geoCoverageContains(
        latitude: 30.01,
        longitude: 31,
        centerLatitude: 30,
        centerLongitude: 31,
        radiusKm: 5,
      ),
      isTrue,
    );
    expect(
      geoCoverageContains(
        latitude: 31,
        longitude: 32,
        centerLatitude: 30,
        centerLongitude: 31,
        radiusKm: 5,
      ),
      isFalse,
    );
  });

  test('supports GeoJSON polygons and bbox fast rejection', () {
    final polygon = <String, dynamic>{
      'type': 'Polygon',
      'coordinates': [
        [
          [30.9, 29.9],
          [31.1, 29.9],
          [31.1, 30.1],
          [30.9, 30.1],
          [30.9, 29.9],
        ],
      ],
    };
    final bbox = <String, dynamic>{
      'west': 30.9,
      'south': 29.9,
      'east': 31.1,
      'north': 30.1,
    };

    expect(
      geoCoverageContains(
        latitude: 30,
        longitude: 31,
        boundaryGeoJson: polygon,
        boundaryBbox: bbox,
      ),
      isTrue,
    );
    expect(
      geoCoverageContains(
        latitude: 30.5,
        longitude: 31.5,
        boundaryGeoJson: polygon,
        boundaryBbox: bbox,
      ),
      isFalse,
    );
  });

  test('uses a bounding box even when no polygon is stored', () {
    final bbox = <String, dynamic>{
      'west': 30.9,
      'south': 29.9,
      'east': 31.1,
      'north': 30.1,
    };

    expect(
      geoCoverageContains(latitude: 30, longitude: 31, boundaryBbox: bbox),
      isTrue,
    );
    expect(
      geoCoverageContains(latitude: 30.2, longitude: 31, boundaryBbox: bbox),
      isFalse,
    );
  });
}
