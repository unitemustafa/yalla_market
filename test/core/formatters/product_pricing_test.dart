import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/formatters/product_pricing.dart';

void main() {
  group('ProductPricing', () {
    test('formats a decimal backend discount as a percentage', () {
      expect(ProductPricing.discountLabel('50.00'), '50%');
      expect(ProductPricing.discountLabel('0.00'), isNull);
    });

    test('applies discount to one price', () {
      expect(
        ProductPricing.formattedPrice('200.00', discount: '50.00'),
        'EGP 100',
      );
      expect(ProductPricing.firstPrice('200.00', discount: '50.00'), 100);
    });

    test('applies discount to a variant price range', () {
      expect(
        ProductPricing.formattedPrice('100.00 ~ 200.00', discount: '50.00'),
        'EGP 50 - 100',
      );
      expect(
        ProductPricing.originalPrice('100.00 ~ 200.00', discount: '50.00'),
        'EGP 100 - 200',
      );
    });
  });
}
