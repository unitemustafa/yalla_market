import '../../../../core/network/api_client.dart';

class GeoapifyPlace {
  const GeoapifyPlace({
    this.placeId,
    this.formattedAddress,
    this.addressLine1,
    this.addressLine2,
    required this.latitude,
    required this.longitude,
    this.resultType,
    this.distanceMeters,
  });

  final String? placeId;
  final String? formattedAddress;
  final String? addressLine1;
  final String? addressLine2;
  final double latitude;
  final double longitude;
  final String? resultType;
  final double? distanceMeters;

  factory GeoapifyPlace.fromJson(Map<String, dynamic> json) {
    final latitude = _doubleFromJson(json['latitude']);
    final longitude = _doubleFromJson(json['longitude']);
    if (latitude == null || longitude == null) {
      throw const FormatException('Geocoding result has no coordinates.');
    }
    return GeoapifyPlace(
      placeId: _stringOrNull(json['place_id']),
      formattedAddress: _stringOrNull(json['formatted_address']),
      addressLine1: _stringOrNull(json['address_line1']),
      addressLine2: _stringOrNull(json['address_line2']),
      latitude: latitude,
      longitude: longitude,
      resultType: _stringOrNull(json['result_type']),
      distanceMeters: _doubleFromJson(json['distance_meters']),
    );
  }

  String get displayAddress =>
      formattedAddress ??
      [addressLine1, addressLine2]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(', ');
}

abstract interface class MapGeocodingDataSource {
  Future<List<GeoapifyPlace>> autocomplete({
    required String query,
    required double latitude,
    required double longitude,
    required String language,
  });

  Future<GeoapifyPlace?> reverse({
    required double latitude,
    required double longitude,
    required String language,
  });
}

class GeoapifyGeocodingDataSource implements MapGeocodingDataSource {
  const GeoapifyGeocodingDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<GeoapifyPlace>> autocomplete({
    required String query,
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final payload = await _apiClient.get<Map<String, dynamic>>(
      '/locations/geocoding/autocomplete/',
      queryParameters: {
        'q': query,
        'latitude': latitude,
        'longitude': longitude,
        'lang': _supportedLanguage(language),
      },
    );
    final items = payload['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => GeoapifyPlace.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<GeoapifyPlace?> reverse({
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final payload = await _apiClient.get<Map<String, dynamic>>(
      '/locations/geocoding/reverse/',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'lang': _supportedLanguage(language),
      },
    );
    final location = payload['location'];
    if (location is! Map) return null;
    return GeoapifyPlace.fromJson(Map<String, dynamic>.from(location));
  }

  String _supportedLanguage(String language) =>
      language.toLowerCase() == 'en' ? 'en' : 'ar';
}

double? _doubleFromJson(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
