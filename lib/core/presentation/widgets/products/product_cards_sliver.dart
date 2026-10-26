import 'package:flutter/material.dart';

import 'product_card_tile_data.dart';
import '../layouts/grid_layout.dart';
import '../selection/category_selection.dart';
import 'product_card_tile.dart';
import 'product_cards/product_card_vertical.dart';

class ProductCardsSliver<T> extends StatefulWidget {
  const ProductCardsSliver({
    super.key,
    required this.products,
    required this.idOf,
    required this.cardOf,
    this.start = 0,
    this.itemCount,
    this.mainAxisExtent = ProductCardVertical.compactGridMainAxisExtent,
    this.maxCrossAxisCount = 3,
    this.categoryKey,
  });

  final List<T> products;
  final String Function(T) idOf;
  final ProductCardTileData Function(T) cardOf;
  final int start;
  final int? itemCount;
  final double mainAxisExtent;
  final int maxCrossAxisCount;
  final Object? categoryKey;

  @override
  State<ProductCardsSliver<T>> createState() => _ProductCardsSliverState<T>();
}

class _ProductCardsSliverState<T> extends State<ProductCardsSliver<T>> {
  Map<String, int> _indices = const {};
  int get _count => widget.itemCount ?? widget.products.length - widget.start;

  @override
  void initState() {
    super.initState();
    _indexProducts();
  }

  @override
  void didUpdateWidget(ProductCardsSliver<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.products, widget.products) ||
        oldWidget.start != widget.start ||
        oldWidget.itemCount != widget.itemCount ||
        !identical(oldWidget.idOf, widget.idOf) ||
        (oldWidget.categoryKey == null) != (widget.categoryKey == null)) {
      _indexProducts();
    }
  }

  void _indexProducts() {
    _indices = widget.categoryKey != null
        ? const {}
        : {
            for (var i = 0; i < _count; i++)
              widget.idOf(widget.products[widget.start + i]): i,
          };
  }

  @override
  Widget build(BuildContext context) => SliverGridLayout(
    itemCount: _count,
    mainAxisExtent: widget.mainAxisExtent,
    minCrossAxisCount: 3,
    maxCrossAxisCount: widget.maxCrossAxisCount,
    findChildIndexCallback: widget.categoryKey == null
        ? (key) => key is ValueKey<String> ? _indices[key.value] : null
        : (key) =>
              key is ValueKey<int> && key.value < _count ? key.value : null,
    itemBuilder: (_, index) {
      final product = widget.cardOf(widget.products[widget.start + index]);
      final tile = ProductCardTile(key: ValueKey(product.id), product: product);
      if (widget.categoryKey == null) return tile;
      // Category fades retain slot identity, while each inner card has its ID.
      return CategoryContentTransition(
        key: ValueKey(index),
        selectionKey: widget.categoryKey!,
        fillPrevious: true,
        child: RepaintBoundary(child: tile),
      );
    },
  );
}
