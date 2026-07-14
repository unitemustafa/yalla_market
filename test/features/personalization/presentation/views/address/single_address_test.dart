import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/personalization/presentation/views/address/widgets/single_address.dart';

void main() {
  testWidgets('shows Egyptian address phones without the country code', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleAddress(
            selectedAddress: true,
            name: 'Home',
            phoneNumber: '+201000000015',
            address: 'Test address',
            city: 'Cairo',
            area: 'Test area',
            deliveryPriceLabel: 'Delivery price is determined later',
          ),
        ),
      ),
    );

    expect(find.text('01000000015'), findsOneWidget);
    expect(find.text('+201000000015'), findsNothing);
  });
}
