import 'dart:math' as math;

const _earthRadiusKm = 6371.0088;

bool geoCoverageContains({
  required double latitude,
  required double longitude,
  Map<String, dynamic>? boundaryGeoJson,
  Map<String, dynamic>? boundaryBbox,
  double? centerLatitude,
  double? centerLongitude,
  double? radiusKm,
}) {
  if (boundaryBbox != null &&
      !_pointInBbox(latitude, longitude, boundaryBbox)) {
    return false;
  }
  if (boundaryGeoJson != null) {
    final polygonResult = _pointInGeoJson(latitude, longitude, boundaryGeoJson);
    if (polygonResult != null) return polygonResult;
  }
  if (boundaryBbox != null) return true;
  if (centerLatitude == null || centerLongitude == null || radiusKm == null) {
    return true;
  }
  return _haversineKm(latitude, longitude, centerLatitude, centerLongitude) <=
      radiusKm;
}

bool hasGeoCoverage({
  Map<String, dynamic>? boundaryGeoJson,
  Map<String, dynamic>? boundaryBbox,
  double? centerLatitude,
  double? centerLongitude,
  double? radiusKm,
}) {
  return boundaryGeoJson != null ||
      boundaryBbox != null ||
      (centerLatitude != null && centerLongitude != null && radiusKm != null);
}

bool? _pointInGeoJson(
  double latitude,
  double longitude,
  Map<String, dynamic> value,
) {
  switch (value['type']) {
    case 'Feature':
      final geometry = _map(value['geometry']);
      return geometry == null
          ? null
          : _pointInGeoJson(latitude, longitude, geometry);
    case 'FeatureCollection':
      final features = value['features'];
      if (features is! List) return null;
      final known = features
          .map(_map)
          .whereType<Map<String, dynamic>>()
          .map((feature) => _pointInGeoJson(latitude, longitude, feature))
          .whereType<bool>()
          .toList(growable: false);
      return known.isEmpty ? null : known.any((result) => result);
    case 'Polygon':
      return _pointInPolygon(latitude, longitude, value['coordinates']);
    case 'MultiPolygon':
      final polygons = value['coordinates'];
      if (polygons is! List) return null;
      return polygons.any(
        (polygon) => _pointInPolygon(latitude, longitude, polygon),
      );
  }
  return null;
}

bool _pointInPolygon(double latitude, double longitude, Object? value) {
  if (value is! List || value.isEmpty) return false;
  if (!_pointInRing(latitude, longitude, value.first)) return false;
  return !value.skip(1).any((ring) => _pointInRing(latitude, longitude, ring));
}

bool _pointInRing(double latitude, double longitude, Object? value) {
  if (value is! List || value.length < 3) return false;
  var inside = false;
  var previous = value.last;
  for (final current in value) {
    final currentPoint = _point(current);
    final previousPoint = _point(previous);
    if (currentPoint == null || previousPoint == null) return false;
    final currentLat = currentPoint.$2;
    final previousLat = previousPoint.$2;
    if ((currentLat > latitude) != (previousLat > latitude)) {
      final crossingLon =
          (previousPoint.$1 - currentPoint.$1) *
              (latitude - currentLat) /
              (previousLat - currentLat) +
          currentPoint.$1;
      if (longitude < crossingLon) inside = !inside;
    }
    previous = current;
  }
  return inside;
}

bool _pointInBbox(
  double latitude,
  double longitude,
  Map<String, dynamic> bbox,
) {
  final west = _number(bbox['west'] ?? bbox['lon1']);
  final south = _number(bbox['south'] ?? bbox['lat1']);
  final east = _number(bbox['east'] ?? bbox['lon2']);
  final north = _number(bbox['north'] ?? bbox['lat2']);
  if (west == null || south == null || east == null || north == null) {
    return true;
  }
  return longitude >= west &&
      longitude <= east &&
      latitude >= south &&
      latitude <= north;
}

double _haversineKm(
  double latitudeA,
  double longitudeA,
  double latitudeB,
  double longitudeB,
) {
  final latA = _radians(latitudeA);
  final latB = _radians(latitudeB);
  final latDelta = latB - latA;
  final lonDelta = _radians(longitudeB - longitudeA);
  final value =
      math.pow(math.sin(latDelta / 2), 2) +
      math.cos(latA) * math.cos(latB) * math.pow(math.sin(lonDelta / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(value)));
}

double _radians(double degrees) => degrees * math.pi / 180;

(double, double)? _point(Object? value) {
  if (value is! List || value.length < 2) return null;
  final longitude = _number(value[0]);
  final latitude = _number(value[1]);
  if (longitude == null || latitude == null) return null;
  return (longitude, latitude);
}

Map<String, dynamic>? _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return null;
}

double? _number(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
