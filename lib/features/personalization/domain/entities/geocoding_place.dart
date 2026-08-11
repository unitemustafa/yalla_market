class GeocodingPlace {
  const GeocodingPlace({
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

  String get displayAddress =>
      formattedAddress ??
      [addressLine1, addressLine2]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(', ');
}
