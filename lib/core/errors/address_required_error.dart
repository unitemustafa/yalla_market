import 'package:dio/dio.dart';

const addressRequiredMessage =
    'راجع عنوان التوصيل المختار لعرض المتاجر والمنتجات المتاحة لك';

bool isAddressRequiredError(DioException error) {
  if (error.response?.statusCode != 400) return false;

  final messages = <String>[];
  _collectMessages(error.response?.data, messages);
  return messages.any((message) {
    final normalized = message.toLowerCase();
    return normalized.contains('user address is required') ||
        normalized.contains('address is required') ||
        normalized.contains('default address is required');
  });
}

void _collectMessages(Object? value, List<String> messages) {
  if (value is String) {
    messages.add(value);
    return;
  }
  if (value is Map) {
    for (final item in value.values) {
      _collectMessages(item, messages);
    }
    return;
  }
  if (value is Iterable) {
    for (final item in value) {
      _collectMessages(item, messages);
    }
  }
}
