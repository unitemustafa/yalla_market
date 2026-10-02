import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';

void main() {
  test('order parses immutable additions without charging them twice', () {
    final item = OrderItemData.fromJson({
      'id': 7,
      'quantity': 2,
      'unit_price': '12.50',
      'additions': [
        {'id': 9, 'name': 'Extra cheese', 'price': '2.50'},
      ],
    });
    expect(item.additions.single.id, '9');
    expect(item.additions.single.name, 'Extra cheese');
    expect(item.additions.single.price, 2.5);
    expect(item.lineTotal, 25);
    final restored = OrderItemData.fromJson(item.toJson());
    expect(restored.additions.single.name, 'Extra cheese');
    expect(restored.lineTotal, 25);
  });
}
