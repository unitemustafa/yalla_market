import '../cache/bounded_memoizer.dart';

typedef _PriceText = ({
  String formatted,
  List<String> numbers,
  List<String> formattedNumbers,
});

class AppCurrency {
  AppCurrency._();

  static const String symbol = 'EGP';
  static final _rangeSeparator = RegExp(r'\s*(?:~|\s-\s)\s*');
  static final _currencyLabel = RegExp(r'EGP|ج\.م|جنيه', caseSensitive: false);
  static final _nonNumber = RegExp(r'[^0-9.,-]');
  static final _trailingZero = RegExp(r'\.0+$');
  static final _prices = BoundedMemoizer<String, _PriceText>(capacity: 256);

  static String format(
    num value, {
    int fractionDigits = 1,
    bool trimTrailingZero = true,
  }) {
    final amount = value.toDouble();
    final text = amount.toStringAsFixed(fractionDigits);
    final cleanText = trimTrailingZero
        ? text.replaceFirst(_trailingZero, '')
        : text;
    return '$symbol $cleanText';
  }

  static String formatPriceText(String? value) {
    return _readPrice(value).formatted;
  }

  static List<String> priceNumbers(String value) =>
      List.of(_readPrice(value).numbers, growable: false);

  /// Display pieces after the existing currency rounding/normalization.
  /// Shared immutable data lets rich price widgets avoid parsing it again.
  static List<String> formattedPriceNumbers(String value) =>
      _readPrice(value).formattedNumbers;

  static _PriceText _readPrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return (formatted: '', numbers: const [], formattedNumbers: const []);
    }
    return _prices.resolve(
      value,
      () => _parsePrice(value),
      // Long external strings should not occupy the shared cache.
      cache: value.length <= 128,
    );
  }

  static _PriceText _parsePrice(String value) {
    final numbers = value
        .split(_rangeSeparator)
        .map(_numberFromText)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    final formattedParts = numbers
        .map(_formatNumberText)
        .toList(growable: false);
    final amounts = formattedParts
        .map((part) => part.replaceFirst('$symbol ', ''))
        .toList(growable: false);
    final formattedNumbers = formattedParts
        .map(_numberFromText)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    return (
      formatted: formattedParts.length <= 1
          ? formattedParts.firstOrNull ?? ''
          : '$symbol ${amounts.join(' - ')}',
      numbers: List.unmodifiable(numbers),
      formattedNumbers: List.unmodifiable(formattedNumbers),
    );
  }

  static String _formatNumberText(String numberText) {
    final parsed = double.tryParse(numberText.replaceAll(',', ''));
    if (parsed == null) return '$symbol $numberText';

    final hasDecimal = numberText.contains('.') && !numberText.endsWith('.00');
    return format(parsed, fractionDigits: hasDecimal ? 1 : 0);
  }

  static String _numberFromText(String value) {
    return value
        .replaceAll(_currencyLabel, '')
        .replaceAll(_nonNumber, '')
        .replaceAll(',', '')
        .trim();
  }
}
