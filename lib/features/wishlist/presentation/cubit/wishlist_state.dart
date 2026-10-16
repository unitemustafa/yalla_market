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

  // This state owns an immutable snapshot. Visible cards share one membership
  // index instead of scanning a long wishlist for each newly built card.
  late final Set<String> _productIds = {
    for (final item in this) item.productId,
  };

  bool containsProduct(String productId) => _productIds.contains(productId);
}
