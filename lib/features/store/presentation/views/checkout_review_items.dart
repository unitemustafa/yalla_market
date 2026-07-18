part of 'checkout_view.dart';

List<CartItemData> _reviewItemsFromPreview(
  List<CartItemData> cartItems,
  OrderPreviewData preview,
) {
  final selectedProductsByVariant = <String, Map<String, dynamic>>{};
  final selectedOffersById = <String, Map<String, dynamic>>{};

  for (final group in preview.marketGroups) {
    for (final product in group.selectedProducts) {
      final variantId = product['variant_id']?.toString();
      if (variantId == null || variantId.isEmpty) continue;
      selectedProductsByVariant[variantId] = {
        ...product,
        '_market_id': group.market['id'],
        '_market_name': group.marketName,
      };
    }
    for (final offer in group.selectedOffers) {
      final offerId = offer['id']?.toString();
      if (offerId == null || offerId.isEmpty) continue;
      final fragmentProducts = _previewMapList(offer['products'])
          .map(
            (product) => <String, dynamic>{
              ...product,
              '_market_id': group.market['id'],
              '_market_name': group.marketName,
            },
          )
          .toList(growable: false);
      final existingOffer = selectedOffersById[offerId];
      if (existingOffer == null) {
        selectedOffersById[offerId] = {...offer, 'products': fragmentProducts};
      } else {
        existingOffer['products'] = [
          ..._previewMapList(existingOffer['products']),
          ...fragmentProducts,
        ];
      }
    }
  }

  final reviewItems = <CartItemData>[];
  for (final cartItem in cartItems) {
    if (!cartItem.isOffer) {
      final previewProduct = cartItem.variantId == null
          ? null
          : selectedProductsByVariant[cartItem.variantId];
      reviewItems.add(
        previewProduct == null
            ? cartItem
            : _reviewItemFromPreviewProduct(
                previewProduct,
                fallback: cartItem,
                idSuffix: 'product',
              ),
      );
      continue;
    }

    final previewOffer =
        selectedOffersById[cartItem.id] ??
        (cartItem.productId == null
            ? null
            : selectedOffersById[cartItem.productId]);
    final products = _previewMapList(previewOffer?['products']);
    if (previewOffer == null || products.isEmpty) {
      reviewItems.add(cartItem);
      continue;
    }

    for (var index = 0; index < products.length; index++) {
      reviewItems.add(
        _reviewItemFromPreviewProduct(
          products[index],
          fallback: cartItem,
          idSuffix: 'offer-$index',
        ),
      );
    }
  }

  return reviewItems;
}

CartItemData _reviewItemFromPreviewProduct(
  Map<String, dynamic> product, {
  required CartItemData fallback,
  required String idSuffix,
}) {
  final variantId = product['variant_id']?.toString() ?? fallback.variantId;
  return CartItemData(
    id: '${fallback.id}-$idSuffix-${variantId ?? 'item'}',
    productId: product['product_id']?.toString() ?? fallback.productId,
    variantId: variantId,
    additionIds: fallback.additionIds,
    marketId: product['_market_id']?.toString() ?? fallback.marketId,
    marketName: product['_market_name']?.toString().trim().isNotEmpty == true
        ? product['_market_name']!.toString()
        : fallback.marketName,
    image: product['image']?.toString().trim().isNotEmpty == true
        ? product['image']!.toString()
        : fallback.image,
    brand: product['_market_name']?.toString().trim().isNotEmpty == true
        ? product['_market_name']!.toString()
        : fallback.brand,
    title: product['product_name']?.toString().trim().isNotEmpty == true
        ? product['product_name']!.toString()
        : fallback.title,
    price: _previewDouble(product['unit_price']) ?? fallback.price,
    quantity: _previewInt(product['quantity']) ?? fallback.quantity,
    attributes: fallback.attributes,
    itemType: fallback.itemType,
    visibilityMode: fallback.visibilityMode,
    regionSlugs: fallback.regionSlugs,
    regionNames: fallback.regionNames,
  );
}

List<Map<String, dynamic>> _previewMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) => <String, dynamic>{
          for (final entry in item.entries)
            if (entry.key is String) entry.key as String: entry.value,
        },
      )
      .toList(growable: false);
}

double? _previewDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _previewInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class _ReviewItemsSection extends StatelessWidget {
  const _ReviewItemsSection({
    required this.items,
    required this.itemCount,
    required this.isDark,
  });

  final List<CartItemData> items;
  final int itemCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('Items'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _SoftBadge(
              label: context.productCount(itemCount),
              icon: AppIcons.shopping_bag,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(items.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : 10,
            ),
            child: _CheckoutItemCard(
              item: items[index],
              isDark: isDark,
              mutedColor: mutedColor,
              textColor: textColor,
            ),
          );
        }),
      ],
    );
  }
}

class _CheckoutItemCard extends StatelessWidget {
  const _CheckoutItemCard({
    required this.item,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
  });

  final CartItemData item;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final imageBackground = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF0F3F8);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 78,
            height: 86,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: imageBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppImage(
              source: item.image,
              fallbackType: AppImagePlaceholderType.product,
              fit: BoxFit.contain,
              cacheWidth: 156,
              cacheHeight: 172,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.tr(item.brand),
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: AppFontSizes.label,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr(item.title),
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppFontSizes.bodyLarge,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.attributes.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: AppFontSizes.label,
                        height: 1.2,
                      ),
                      children: _attributeSpans(context, item.attributes),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 13),
                Row(
                  children: [
                    _QuantityPill(quantity: item.quantity, isDark: isDark),
                    const Spacer(),
                    AppCurrencyText(
                      text: _formatMoney(item.price * item.quantity),
                      style: TextStyle(
                        color: textColor,
                        fontSize: AppFontSizes.bodyLarge,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _attributeSpans(
    BuildContext context,
    List<CartItemAttribute> attributes,
  ) {
    return [
      for (final attribute in attributes) ...[
        TextSpan(text: '${context.tr(attribute.label)} '),
        TextSpan(
          text: '${context.tr(attribute.value)} ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ];
  }
}
