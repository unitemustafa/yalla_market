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
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String street;
  final String district;
  final String postalCode;
  final String city;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  factory AddressData.fromJson(Map<String, dynamic> json) {
    return AddressData(
      id: json['id']?.toString() ?? '',
      name:
          json['name']?.toString() ??
          json['fullName']?.toString() ??
          json['full_name']?.toString() ??
          '',
      phoneNumber:
          json['phoneNumber']?.toString() ??
          json['phone_number']?.toString() ??
          json['phone']?.toString() ??
          '',
      street:
          json['street']?.toString() ??
          json['line1']?.toString() ??
          json['address']?.toString() ??
          '',
      district:
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
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      latitude: _doubleFromJson(json['latitude']),
      longitude: _doubleFromJson(json['longitude']),
      isDefault:
          json['isDefault'] as bool? ??
          json['is_default'] as bool? ??
          json['default'] as bool? ??
          json['selected'] as bool? ??
          false,
    );
  }

  String get fullAddress {
    final parts = [
      street,
      district,
      city,
      state,
      country,
    ].where((part) => part.trim().isNotEmpty).toList();

    return parts.join(', ');
  }

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
    };
  }

  Map<String, Object?> toApiJson() {
    return {
      'line1': _lineWithDistrict,
      'city': city,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
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
    );
  }

  String get _lineWithDistrict {
    final cleanStreet = street.trim();
    final cleanDistrict = district.trim();
    if (cleanDistrict.isEmpty) return cleanStreet;
    if (cleanStreet.isEmpty) return cleanDistrict;
    if (cleanStreet.toLowerCase().contains(cleanDistrict.toLowerCase())) {
      return cleanStreet;
    }
    return '$cleanStreet, $cleanDistrict';
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
