class OrderAdditionData {
  const OrderAdditionData({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  factory OrderAdditionData.fromJson(Map<String, dynamic> json) =>
      OrderAdditionData(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      );

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'price': price};
}
