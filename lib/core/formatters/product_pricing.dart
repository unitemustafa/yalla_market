import 'app_currency.dart';
import '../cache/bounded_memoizer.dart';

typedef _PricePresentation = ({
  String displayed,
  String original,
  double first,
});

class ProductPricing {
  const ProductPricing._();
  static final _nonNumber = RegExp(r'[^0-9.,-]');
  static final _rangeSeparator = RegExp(r'\s*(?:~|\s-\s)\s*');
  static final _presentations =
      BoundedMemoizer<(String?, String?), _PricePresentation>(capacity: 256);

  static double discountPercent(String? value) {
    if (value == null || value.isEmpty) return 0;
    final parsed = double.tryParse(
      value.replaceAll(_nonNumber, '').replaceAll(',', ''),
    );
    if (parsed == null || parsed <= 0) return 0;
    return parsed.clamp(0, 100).toDouble();
  }

  static String? discountLabel(String? value) {
    final percent = discountPercent(value);
    if (percent <= 0) return null;
    return '${_numberText(percent)}%';
  }

  static double firstPrice(String? value, {String? discount}) {
    return _presentation(value, discount).first;
  }

  static List<double> priceValues(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(_rangeSeparator)
        .map(
          (part) => double.tryParse(
            part.replaceAll(_nonNumber, '').replaceAll(',', ''),
          ),
        )
        .whereType<double>()
        .toList(growable: false);
  }

  static String formattedPrice(String? value, {String? discount}) {
    return _presentation(value, discount).displayed;
  }

  static String originalPrice(String? value, {String? discount}) {
    return _presentation(value, discount).original;
  }

  static _PricePresentation _presentation(String? value, String? discount) =>
      _presentations.resolve(
        (value, discount),
        () => _preparePresentation(value, discount),
        cache: (value?.length ?? 0) <= 128 && (discount?.length ?? 0) <= 128,
      );

  static _PricePresentation _preparePresentation(
    String? value,
    String? discount,
  ) {
    final prices = priceValues(value);
    if (prices.isEmpty) return (displayed: '', original: '', first: 0);
    final percent = discountPercent(discount);
    final factor = 1 - percent / 100;
    return (
      displayed: _formatRange(prices, factor),
      original: percent > 0 ? _formatRange(prices, 1) : '',
      first: prices.first * factor,
    );
  }

  static String _formatRange(List<double> prices, double factor) {
    var minimum = prices.first * factor;
    var maximum = minimum;
    for (var index = 1; index < prices.length; index++) {
      final amount = prices[index] * factor;
      minimum = minimum < amount ? minimum : amount;
      maximum = maximum > amount ? maximum : amount;
    }
    final minimumText = AppCurrency.format(minimum);
    if ((maximum - minimum).abs() < 0.001) return minimumText;
    final maximumText = AppCurrency.format(
      maximum,
    ).replaceFirst('${AppCurrency.symbol} ', '');
    return '$minimumText - $maximumText';
  }

  static String _numberText(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
