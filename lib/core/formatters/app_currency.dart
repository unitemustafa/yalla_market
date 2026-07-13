class AppCurrency {
  AppCurrency._();

  static const String symbol = 'EGP';

  static String format(
    num value, {
    int fractionDigits = 1,
    bool trimTrailingZero = true,
  }) {
    final amount = value.toDouble();
    final text = amount.toStringAsFixed(fractionDigits);
    final cleanText = trimTrailingZero
        ? text.replaceFirst(RegExp(r'\.0+$'), '')
        : text;
    return '$symbol $cleanText';
  }

  static String formatPriceText(String? value) {
    if (value == null || value.trim().isEmpty) return '';

    final parts = value.split(RegExp(r'\s*(?:~|\s-\s)\s*'));
    final formattedParts = parts
        .map(_formatPricePart)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (formattedParts.length <= 1) return formattedParts.firstOrNull ?? '';
    final amounts = formattedParts
        .map((part) => part.replaceFirst('$symbol ', ''))
        .toList(growable: false);
    return '$symbol ${amounts.join(' - ')}';
  }

  static List<String> priceNumbers(String value) {
    return value
        .split(RegExp(r'\s*(?:~|\s-\s)\s*'))
        .map(_numberFromText)
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  static String _formatPricePart(String value) {
    final numberText = _numberFromText(value);
    if (numberText.isEmpty) return '';

    final parsed = double.tryParse(numberText.replaceAll(',', ''));
    if (parsed == null) return '$symbol $numberText';

    final hasDecimal = numberText.contains('.') && !numberText.endsWith('.00');
    return format(parsed, fractionDigits: hasDecimal ? 1 : 0);
  }

  static String _numberFromText(String value) {
    return value
        .replaceAll(RegExp(r'EGP|ج\.م|جنيه', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^0-9.,-]'), '')
        .replaceAll(',', '')
        .trim();
  }
}
