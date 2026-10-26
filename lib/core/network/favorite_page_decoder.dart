import '../domain/favorite_page.dart';
import 'data_page_decoder.dart';

FavoritePage<T> decodeFavoritePage<T>(
  Map<String, dynamic> payload,
  T Function(Map<String, dynamic>) decode, {
  required bool requireIds,
}) {
  final page = decodeDataPage(payload, decode);
  final raw = payload['liked_ids'];
  if (requireIds && raw is! List) {
    throw const FormatException('Missing favorite membership');
  }
  Set<String>? ids;
  if (raw != null) {
    if (raw is! List ||
        raw.any((v) => (v is! int && v is! String) || v.toString().isEmpty)) {
      throw const FormatException('Invalid favorite membership');
    }
    ids = Set.unmodifiable(raw.map((v) => v.toString()));
    if (ids.length != raw.length) {
      throw const FormatException('Duplicate favorite membership');
    }
  }
  return FavoritePage(
    items: page.items,
    count: page.count,
    hasMore: page.hasMore,
    favoriteIds: ids,
  );
}
