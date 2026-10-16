import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/formatters/app_currency.dart';

void main() {
  group('AppCurrency', () {
    test('formats numeric values with the shared Egyptian pound label', () {
      expect(AppCurrency.format(120), 'EGP 120');
      expect(AppCurrency.format(84.5, fractionDigits: 2), 'EGP 84.50');
    });

    test('normalizes EGP and Arabic currency text from product prices', () {
      expect(
        AppCurrency.formatPriceText('EGP 120.00 - EGP 180.00'),
        'EGP 120 - 180',
      );
      expect(AppCurrency.formatPriceText('120.00 ~ 180.00'), 'EGP 120 - 180');
      expect(AppCurrency.formatPriceText('35 ج.م'), 'EGP 35');
    });

    test('extracts numeric parts for rich currency widgets', () {
      expect(AppCurrency.priceNumbers('EGP 24.50 - EGP 32.00'), [
        '24.50',
        '32.00',
      ]);
    });

    test('formats simple, decimal, comma, negative, and range price text', () {
      expect(AppCurrency.formatPriceText('42'), 'EGP 42');
      expect(AppCurrency.formatPriceText('24.50'), 'EGP 24.5');
      expect(AppCurrency.formatPriceText('1,200.00'), 'EGP 1200');
      expect(AppCurrency.formatPriceText('-12.50'), 'EGP -12.5');
      expect(AppCurrency.formatPriceText('10~20'), 'EGP 10 - 20');
      expect(AppCurrency.formatPriceText('10 - 20'), 'EGP 10 - 20');
    });

    test(
      'returns empty display values for null, empty, and malformed prices',
      () {
        expect(AppCurrency.formatPriceText(null), isEmpty);
        expect(AppCurrency.formatPriceText('  '), isEmpty);
        expect(AppCurrency.formatPriceText('not a price'), isEmpty);
        expect(AppCurrency.formattedPriceNumbers('not a price'), isEmpty);
      },
    );

    test(
      'keeps returned numeric lists isolated and display numbers immutable',
      () {
        final first = AppCurrency.priceNumbers('EGP 24.50 - EGP 32.00');
        first[0] = 'changed';

        expect(AppCurrency.priceNumbers('EGP 24.50 - EGP 32.00'), [
          '24.50',
          '32.00',
        ]);
        final display = AppCurrency.formattedPriceNumbers(
          'EGP 24.50 - EGP 32.00',
        );
        expect(display, ['24.5', '32']);
        expect(() => display[0] = 'changed', throwsUnsupportedError);
      },
    );

    test('returns deterministic canonical pieces for repeated raw values', () {
      final raw = 'EGP 1,200.00 - EGP 1,250.50';

      expect(
        AppCurrency.formattedPriceNumbers(raw),
        AppCurrency.priceNumbers(AppCurrency.formatPriceText(raw)),
      );
      expect(
        AppCurrency.formattedPriceNumbers(raw),
        AppCurrency.formattedPriceNumbers(raw),
      );
    });
  });
}
