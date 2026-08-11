import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/presentation/views/orders/widgets/order_list_item.dart';

void main() {
  testWidgets('expanded order preview shows every product name', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrderListItem(
              status: 'Pending',
              date: '06 Aug 2026',
              orderId: '#123',
              shippingDate: '07 Aug 2026',
              itemCount: 3,
              total: '150 EGP',
              statusColor: Colors.orange,
              products: [
                OrderListItemProduct(title: 'First product', quantity: 1),
                OrderListItemProduct(title: 'Second product', quantity: 1),
                OrderListItemProduct(title: 'Third product', quantity: 1),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();

    expect(find.textContaining('First product'), findsOneWidget);
    expect(find.textContaining('Second product'), findsOneWidget);
    expect(find.textContaining('Third product'), findsOneWidget);
    expect(find.textContaining('+ 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
