import 'dart:collection';

import '../../domain/entities/wishlist_item.dart';

/// Retains the existing list API while carrying presentation load status.
class WishlistState extends UnmodifiableListView<WishlistItem> {
  WishlistState(
    Iterable<WishlistItem> items, {
    this.loading = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.errorRevision = 0,
  }) : super(List<WishlistItem>.of(items, growable: false));

  final bool loading;
  final bool hasLoaded;
  final String? errorMessage;
  final int errorRevision;
}
