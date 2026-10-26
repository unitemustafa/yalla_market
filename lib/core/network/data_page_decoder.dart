import '../domain/data_page.dart';

DataPage<T> decodeDataPage<T>(
  Object? payload,
  T Function(Map<String, dynamic>) decode, {
  int maxItems = 30,
}) {
  if (payload is! Map<String, dynamic>) {
    throw const FormatException('Invalid page');
  }
  final items = payload['results'];
  final count = payload['count'];
  final next = payload['next'];
  if (items is! List ||
      items.length > maxItems ||
      count is! int ||
      count < 0 ||
      (next != null && (next is! String || next.isEmpty))) {
    throw const FormatException('Invalid page metadata');
  }
  return DataPage(
    items: List.unmodifiable(
      items.map((raw) {
        if (raw is! Map<String, dynamic> ||
            (raw['id']?.toString() ?? '').isEmpty) {
          throw const FormatException('Invalid page item');
        }
        return decode(raw);
      }),
    ),
    count: count,
    hasMore: next != null,
  );
}
