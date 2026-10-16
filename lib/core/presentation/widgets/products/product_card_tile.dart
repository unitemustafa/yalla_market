import 'package:flutter/material.dart';

import 'product_card_tile_data.dart';
import 'product_cards/product_card_vertical.dart';

/// Retains only a mounted tile's card. Appending or rebuilding a list does not
/// rebuild unchanged cards; their own theme, cart and wishlist listeners live on.
class ProductCardTile extends StatefulWidget {
  const ProductCardTile({
    super.key,
    required this.product,
    this.compact = true,
  });

  final ProductCardTileData product;
  final bool compact;

  @override
  State<ProductCardTile> createState() => _ProductCardTileState();
}

class _ProductCardTileState extends State<ProductCardTile> {
  late ProductCardVertical _card;

  Object _inputs(ProductCardTile tile) {
    final p = tile.product;
    return (
      p.id,
      p.image,
      p.title,
      p.brand,
      p.price,
      p.slug,
      p.defaultVariantId,
      p.marketId,
      p.oldPrice,
      p.discount,
      tile.compact,
    );
  }

  @override
  void initState() {
    super.initState();
    _updateCard();
  }

  @override
  void didUpdateWidget(ProductCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_inputs(oldWidget) != _inputs(widget)) _updateCard();
  }

  void _updateCard() {
    final p = widget.product;
    _card = ProductCardVertical(
      key: ValueKey(p.id),
      image: p.image,
      title: p.title,
      brand: p.brand,
      price: p.price,
      productId: p.id,
      productSlug: p.slug,
      defaultVariantId: p.defaultVariantId,
      marketId: p.marketId,
      marketName: p.brand,
      oldPrice: p.oldPrice,
      discount: p.discount,
      compact: widget.compact,
    );
  }

  @override
  Widget build(BuildContext context) => _card;
}
