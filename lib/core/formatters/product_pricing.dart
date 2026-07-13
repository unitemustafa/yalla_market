import 'app_currency.dart';

class ProductPricing {
  const ProductPricing._();

  static double discountPercent(String? value) {
    if (value == null) return 0;
    final parsed = double.tryParse(
      value.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', ''),
    );
    if (parsed == null || parsed <= 0) return 0;
    return parsed.clamp(0, 100).toDouble();
  }

  static String? discountLabel(String? value) {
    final percent = discountPercent(value);
    if (percent <= 0) return null;
    return '${_numberText(percent)}%';
  }

  static double applyDiscount(double price, String? discount) {
    final percent = discountPercent(discount);
    return price * (1 - (percent / 100));
  }

  static double firstPrice(String? value, {String? discount}) {
    final prices = priceValues(value);
    if (prices.isEmpty) return 0;
    return applyDiscount(prices.first, discount);
  }

  static List<double> priceValues(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(RegExp(r'\s*(?:~|\s-\s)\s*'))
        .map(
          (part) => double.tryParse(
            part.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', ''),
          ),
        )
        .whereType<double>()
        .toList(growable: false);
  }

  static String formattedPrice(String? value, {String? discount}) {
    final prices = priceValues(value);
    if (prices.isEmpty) return '';

    final discounted = prices
        .map((price) => applyDiscount(price, discount))
        .toList(growable: false);
    final minimum = discounted.reduce((a, b) => a < b ? a : b);
    final maximum = discounted.reduce((a, b) => a > b ? a : b);
    final minimumText = AppCurrency.format(minimum);
    if ((maximum - minimum).abs() < 0.001) return minimumText;
    final maximumText = AppCurrency.format(
      maximum,
    ).replaceFirst('${AppCurrency.symbol} ', '');
    return '$minimumText - $maximumText';
  }

  static String originalPrice(String? value, {String? discount}) {
    return discountPercent(discount) > 0 ? formattedPrice(value) : '';
  }

  static String _numberText(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
