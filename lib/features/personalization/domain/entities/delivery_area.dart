class DeliveryArea {
  const DeliveryArea({
    required this.id,
    required this.serviceCityId,
    required this.name,
    required this.deliveryPrice,
    required this.isActive,
  });

  final int id;
  final int serviceCityId;
  final String name;
  final double? deliveryPrice;
  final bool isActive;

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
