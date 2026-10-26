import 'dart:collection';

import '../../domain/entities/wishlist_item.dart';

/// Retains the existing list API while carrying presentation load status.
class WishlistState extends UnmodifiableListView<WishlistItem> {
  WishlistState(
    Iterable<WishlistItem> items, {
    this.loading = false,
    this.favoriteIds,
    this.hasMore = false,
    this.loadingMore = false,
    this.moreError,
    this.hasLoaded = false,
    this.errorMessage,
    this.errorRevision = 0,
  }) : super(List<WishlistItem>.of(items, growable: false));

  final Set<String>? favoriteIds;
  final bool hasMore;
  final bool loadingMore;
  final String? moreError;
  final bool loading;
  final bool hasLoaded;
  final String? errorMessage;
  final int errorRevision;

  // This state owns an immutable snapshot. Visible cards share one membership
  // index instead of scanning a long wishlist for each newly built card.
  late final Set<String> _productIds =
      favoriteIds ?? {for (final item in this) item.productId};

  bool containsProduct(String productId) => _productIds.contains(productId);
  WishlistState copyWith({
    Iterable<WishlistItem>? items,
    bool? loading,
    bool? hasLoaded,
    Set<String>? favoriteIds,
    bool? hasMore,
    bool? loadingMore,
    String? errorMessage,
    int? errorRevision,
    String? moreError,
    bool clearError = false,
    bool clearMoreError = false,
  }) => WishlistState(
    items ?? this,
    loading: loading ?? this.loading,
    hasLoaded: hasLoaded ?? this.hasLoaded,
    favoriteIds: favoriteIds ?? this.favoriteIds,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    errorRevision: errorRevision ?? this.errorRevision,
    moreError: clearMoreError ? null : moreError ?? this.moreError,
  );
}
