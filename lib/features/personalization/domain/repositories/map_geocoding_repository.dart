import '../entities/geocoding_place.dart';

abstract interface class MapGeocodingRepository {
  Future<List<GeocodingPlace>> autocomplete({
    required String query,
    required double latitude,
    required double longitude,
    required String language,
  });

  Future<GeocodingPlace?> reverse({
    required double latitude,
    required double longitude,
    required String language,
  });
}
