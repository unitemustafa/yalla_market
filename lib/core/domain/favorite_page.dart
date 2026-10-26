import 'data_page.dart';

class FavoritePage<T> extends DataPage<T> {
  const FavoritePage({
    required super.items,
    required super.count,
    required super.hasMore,
    this.favoriteIds,
  });
  final Set<String>? favoriteIds;
}
