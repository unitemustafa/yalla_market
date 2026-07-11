class AddressData {
  const AddressData({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.street,
    this.district = '',
    required this.postalCode,
    required this.city,
    required this.state,
    required this.country,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.manualCity,
    this.manualArea,
    this.serviceCityId,
    this.serviceCityName,
    this.serviceCityIsActive,
    this.deliveryAreaId,
    this.deliveryAreaName,
    this.deliveryAreaPrice,
    this.deliveryAreaIsActive,
    this.deliveryType,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String street;
  String get details => street;
  final String district;
  final String postalCode;
  final String city;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final String? manualCity;
  final String? manualArea;
  final int? serviceCityId;
  final String? serviceCityName;
  final bool? serviceCityIsActive;
  final int? deliveryAreaId;
  final String? deliveryAreaName;
  final double? deliveryAreaPrice;
  final bool? deliveryAreaIsActive;
  final String? deliveryType;

  factory AddressData.fromJson(Map<String, dynamic> json) {
    return AddressData(
      id: json['id']?.toString() ?? '',
      name:
          json['name']?.toString() ??
          json['fullName']?.toString() ??
          json['full_name']?.toString() ??
          '',
      phoneNumber:
          json['phone']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['phone_number']?.toString() ??
          '',
      street:
          json['details']?.toString() ??
          json['line1']?.toString() ??
          json['street']?.toString() ??
          json['address']?.toString() ??
          '',
      district:
          json['manual_area']?.toString() ??
          json['district']?.toString() ??
          json['area']?.toString() ??
          json['region']?.toString() ??
          json['delivery_area_name']?.toString() ??
          _deliveryAreaName(json['delivery_area']) ??
          '',
      postalCode:
          json['postalCode']?.toString() ??
          json['postal_code']?.toString() ??
          '',
      city:
          json['service_city_name']?.toString() ??
          _serviceCityName(json['service_city']) ??
          json['manual_city']?.toString() ??
          json['city']?.toString() ??
          '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      latitude: _doubleFromJson(json['latitude']),
      longitude: _doubleFromJson(json['longitude']),
      isDefault:
          _boolFromJson(json['is_default']) ??
          _boolFromJson(json['isDefault']) ??
          json['default'] as bool? ??
          json['selected'] as bool? ??
          false,
      manualCity: _stringOrNull(json['manual_city']),
      manualArea: _stringOrNull(json['manual_area']),
      serviceCityId: _intFromJson(
        json['service_city_id'] ?? _nestedValue(json['service_city'], 'id'),
      ),
      serviceCityName:
          _stringOrNull(json['service_city_name']) ??
          _stringOrNull(_nestedValue(json['service_city'], 'name')),
      serviceCityIsActive: _boolFromJson(
        _nestedValue(json['service_city'], 'is_active'),
      ),
      deliveryAreaId: _intFromJson(
        json['delivery_area_id'] ?? _nestedValue(json['delivery_area'], 'id'),
      ),
      deliveryAreaName:
          _stringOrNull(json['delivery_area_name']) ??
          _stringOrNull(_nestedValue(json['delivery_area'], 'name')),
      deliveryAreaPrice: _doubleFromJson(
        json['delivery_area_price'] ?? json['delivery_price_preview'],
      ),
      deliveryAreaIsActive: _boolFromJson(
        _nestedValue(json['delivery_area'], 'is_active'),
      ),
      deliveryType: _stringOrNull(json['delivery_type']),
    );
  }

  String get fullAddress {
    final parts = [
      street,
      areaLabel,
      cityLabel,
      state,
      country,
    ].where((part) => part.trim().isNotEmpty).toList();

    return parts.join(', ');
  }

  String get cityLabel => serviceCityName ?? manualCity ?? city;

  String get areaLabel => deliveryAreaName ?? manualArea ?? district;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'street': street,
      'district': district,
      'postalCode': postalCode,
      'city': city,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'manualCity': manualCity,
      'manualArea': manualArea,
      'serviceCityId': serviceCityId,
      'serviceCityName': serviceCityName,
      'serviceCityIsActive': serviceCityIsActive,
      'deliveryAreaId': deliveryAreaId,
      'deliveryAreaName': deliveryAreaName,
      'deliveryAreaPrice': deliveryAreaPrice,
      'deliveryAreaIsActive': deliveryAreaIsActive,
      'deliveryType': deliveryType,
    };
  }

  Map<String, Object?> toApiJson() {
    return {
      'name': name,
      'details': street,
      'service_city_id': serviceCityId,
      'delivery_area_id': deliveryAreaId,
      'manual_city': manualCity,
      'manual_area': manualArea,
      'is_default': isDefault,
    };
  }

  AddressData copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? street,
    String? district,
    String? postalCode,
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    bool? isDefault,
    String? manualCity,
    String? manualArea,
    int? serviceCityId,
    String? serviceCityName,
    bool? serviceCityIsActive,
    int? deliveryAreaId,
    String? deliveryAreaName,
    double? deliveryAreaPrice,
    bool? deliveryAreaIsActive,
    String? deliveryType,
  }) {
    return AddressData(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      street: street ?? this.street,
      district: district ?? this.district,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      manualCity: manualCity ?? this.manualCity,
      manualArea: manualArea ?? this.manualArea,
      serviceCityId: serviceCityId ?? this.serviceCityId,
      serviceCityName: serviceCityName ?? this.serviceCityName,
      serviceCityIsActive: serviceCityIsActive ?? this.serviceCityIsActive,
      deliveryAreaId: deliveryAreaId ?? this.deliveryAreaId,
      deliveryAreaName: deliveryAreaName ?? this.deliveryAreaName,
      deliveryAreaPrice: deliveryAreaPrice ?? this.deliveryAreaPrice,
      deliveryAreaIsActive: deliveryAreaIsActive ?? this.deliveryAreaIsActive,
      deliveryType: deliveryType ?? this.deliveryType,
    );
  }
}

String? _deliveryAreaName(Object? value) {
  if (value is Map<String, dynamic>) {
    return value['name']?.toString();
  }
  return null;
}

double? _doubleFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is String) return bool.tryParse(value);
  return null;
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

Object? _nestedValue(Object? value, String key) {
  if (value is Map<String, dynamic>) return value[key];
  return null;
}

String? _serviceCityName(Object? value) {
  if (value is Map<String, dynamic>) {
    return value['name']?.toString();
  }
  return null;
}
