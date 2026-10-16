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

    test(
      'clamps excessive discounts and preserves original range semantics',
      () {
        expect(ProductPricing.discountPercent('150'), 100);
        expect(ProductPricing.discountLabel('150'), '100%');
        expect(
          ProductPricing.formattedPrice('100.00 ~ 200.00', discount: '150'),
          'EGP 0',
        );
        expect(
          ProductPricing.originalPrice('100.00 ~ 200.00', discount: '150'),
          'EGP 100 - 200',
        );
      },
    );

    test(
      'returns stable empty output for null, empty, and malformed prices',
      () {
        for (final value in <String?>[null, '', '   ', 'unpriced']) {
          expect(ProductPricing.formattedPrice(value, discount: '20'), isEmpty);
          expect(ProductPricing.originalPrice(value, discount: '20'), isEmpty);
          expect(ProductPricing.firstPrice(value, discount: '20'), 0);
        }
      },
    );

    test('formats comma decimals and negative discounts deterministically', () {
      expect(
        ProductPricing.formattedPrice('1,200.50', discount: '10'),
        'EGP 1080.5',
      );
      expect(ProductPricing.discountLabel('-20'), isNull);
      expect(ProductPricing.formattedPrice('200', discount: '-20'), 'EGP 200');
      expect(
        ProductPricing.formattedPrice('100 - 200', discount: '50'),
        'EGP 50 - 100',
      );
    });
  });
}
