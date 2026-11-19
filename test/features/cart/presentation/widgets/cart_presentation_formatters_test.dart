import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/cart/presentation/widgets/cart_presentation_formatters.dart';

void main() {
  test('cart prices preserve the cents charged by checkout', () {
    expect(formatCartMoney(13.95), 'EGP 13.95');
    expect(formatCartMoney(13.95 * 2), 'EGP 27.9');
    expect(formatCartMoney(0.01), 'EGP 0.01');
  });

  test('explicit cart precision keeps its existing presentation', () {
    expect(formatCartMoney(10.5, fractionDigits: 2), 'EGP 10.50');
    expect(formatCartMoney(10, fractionDigits: 2), 'EGP 10');
  });
}
