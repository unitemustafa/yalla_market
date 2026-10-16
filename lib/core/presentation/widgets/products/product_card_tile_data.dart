/// Render/action inputs for a tile; independent of feature/domain entities.
class ProductCardTileData {
  const ProductCardTileData({
    required this.id,
    required this.image,
    required this.title,
    required this.brand,
    required this.price,
    this.slug,
    this.defaultVariantId,
    this.marketId,
    this.oldPrice,
    this.discount,
  });

  final String id, image, title, brand, price;
  final String? slug, defaultVariantId, marketId, oldPrice, discount;
}
