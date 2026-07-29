class DeliveryArea {
  const DeliveryArea({
    required this.id,
    required this.serviceCityId,
    required this.name,
    required this.deliveryPrice,
    required this.isActive,
    this.centerLatitude,
    this.centerLongitude,
    this.radiusKm,
    this.boundaryGeoJson,
    this.boundaryBbox,
    this.etaMinMinutes,
    this.etaMaxMinutes,
  });

  final int id;
  final int serviceCityId;
  final String name;
  final double? deliveryPrice;
  final bool isActive;
  final double? centerLatitude;
  final double? centerLongitude;
  final double? radiusKm;
  final Map<String, dynamic>? boundaryGeoJson;
  final Map<String, dynamic>? boundaryBbox;
  final int? etaMinMinutes;
  final int? etaMaxMinutes;

  factory DeliveryArea.fromJson(Map<String, dynamic> json) {
    return DeliveryArea(
      id: _intFromJson(json['id']) ?? 0,
      serviceCityId:
          _intFromJson(json['service_city_id']) ??
          _intFromJson(_nestedValue(json['service_city'], 'id')) ??
          0,
      name: json['name']?.toString().trim() ?? '',
      deliveryPrice: _doubleFromJson(json['delivery_price']),
      isActive: _boolFromJson(json['is_active']) ?? true,
      centerLatitude: _doubleFromJson(json['center_latitude']),
      centerLongitude: _doubleFromJson(json['center_longitude']),
      radiusKm: _doubleFromJson(json['radius_km']),
      boundaryGeoJson: _mapFromJson(json['boundary_geojson']),
      boundaryBbox: _bboxFromJson(json['boundary_bbox']),
      etaMinMinutes: _intFromJson(json['eta_min_minutes']),
      etaMaxMinutes: _intFromJson(json['eta_max_minutes']),
    );
  }

  bool get isValid => id > 0 && serviceCityId > 0 && name.isNotEmpty;
}

int? _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _doubleFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is String) return bool.tryParse(value);
  return null;
}

Object? _nestedValue(Object? value, String key) {
  if (value is Map<String, dynamic>) return value[key];
  return null;
}

Map<String, dynamic>? _mapFromJson(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  return null;
}

Map<String, dynamic>? _bboxFromJson(Object? value) {
  final mapped = _mapFromJson(value);
  if (mapped != null) return mapped;
  if (value is List && value.length >= 4) {
    return {
      'west': value[0],
      'south': value[1],
      'east': value[2],
      'north': value[3],
    };
  }
  return null;
}
