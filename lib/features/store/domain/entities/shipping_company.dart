class ShippingCompanyData {
  const ShippingCompanyData({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  final int id;
  final String name;
  final String? logoUrl;

  factory ShippingCompanyData.fromJson(Map<String, dynamic> json) {
    return ShippingCompanyData(
      id: _intFromJson(json['id']) ?? 0,
      name: json['name']?.toString().trim() ?? '',
      logoUrl: _stringOrNull(json['logo_url'] ?? json['logoUrl']),
    );
  }

  bool get isValid => id > 0 && name.isNotEmpty;
}

int? _intFromJson(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
