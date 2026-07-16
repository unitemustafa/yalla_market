import 'package:flutter/material.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../constants/app_colors.dart';
import '../../../../formatters/app_currency.dart';
import '../../../../formatters/product_pricing.dart';
import '../../../../localization/app_translations.dart';
import '../../../../routing/app_route_arguments.dart';
import '../../../../routing/app_routes.dart';
import '../../../../../features/cart/domain/entities/cart_item.dart';
import '../../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../../features/wishlist/domain/entities/wishlist_item.dart';
import '../../../../../features/wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../snackbars/custom_snackbar.dart';

import '../../texts/app_currency_text.dart';
import '../../texts/green_currency_price.dart';

String? _discountBadgeLabel(BuildContext context, String? discount) {
  final percentage = ProductPricing.discountLabel(discount);
  if (percentage == null) return null;
  return context.isArabicLanguage ? 'خصم $percentage' : '$percentage OFF';
}

class ProductCardVertical extends StatefulWidget {
  const ProductCardVertical({
    super.key,
    required this.image,
    required this.title,
    required this.brand,
    required this.price,
    required this.productId,
    this.productSlug,
    this.defaultVariantId,
    this.marketId,
    this.marketName,
    this.oldPrice,
    this.discount,
  });

  final String image, title, brand, price;
  final String productId;
  final String? productSlug, defaultVariantId, marketId, marketName;
  final String? oldPrice, discount;

  @override
  State<ProductCardVertical> createState() => _ProductCardVerticalState();
}

class _ProductCardVerticalState extends State<ProductCardVertical> {
  String get _resolvedProductId => widget.productId;

  String? get _resolvedVariantId {
    final variantId = widget.defaultVariantId?.trim();
    return variantId == null || variantId.isEmpty ? null : variantId;
  }

  String get _resolvedCartItemId => _resolvedVariantId ?? _resolvedProductId;

  String _formatPrice(String? price) {
    return AppCurrency.formatPriceText(price);
  }

  void _openProductDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: ProductDetailRouteArgs(
        image: widget.image,
        title: widget.title,
        brand: widget.brand,
        price: widget.price,
        productId: widget.productId,
        productSlug: widget.productSlug,
        oldPrice: widget.oldPrice,
        discount: widget.discount,
      ),
    );
  }

  void _toggleWishlist(BuildContext context, bool wasFavorite) {
    final displayedPrice = ProductPricing.formattedPrice(
      widget.price,
      discount: widget.discount,
    );
    final originalPrice = ProductPricing.originalPrice(
      widget.price,
      discount: widget.discount,
    );

    final item = WishlistItem(
      productId: _resolvedProductId,
      image: widget.image,
      title: widget.title,
      brand: widget.brand,
      price: displayedPrice,
      oldPrice: originalPrice.isNotEmpty ? originalPrice : widget.oldPrice,
      discount: _discountBadgeLabel(context, widget.discount),
    );

    context.read<WishlistCubit>().toggleItem(item);
    if (wasFavorite) {
      CustomSnackBar.showRemoved(
        context: context,
        title: 'Item removed from wishlist',
      );
    } else {
      CustomSnackBar.showAdded(
        context: context,
        title: 'Item added to wishlist',
      );
    }
  }

  void _addToCart(BuildContext context) {
    context.read<CartCubit>().addItem(
      CartItemData(
        id: _resolvedCartItemId,
        productId: _resolvedProductId,
        variantId: _resolvedVariantId,
        marketId: widget.marketId,
        marketName: widget.marketName ?? widget.brand,
        image: widget.image,
        brand: widget.brand,
        title: widget.title,
        price: ProductPricing.firstPrice(
          widget.price,
          discount: widget.discount,
        ),
        quantity: 1,
      ),
      1,
    );
    CustomSnackBar.showAdded(context: context, title: 'Product added to cart');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final imagePanelColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF1F3F8);
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final discount = _discountBadgeLabel(context, widget.discount);
    final displayedPrice = ProductPricing.formattedPrice(
      widget.price,
      discount: widget.discount,
    );
    final originalPrice = ProductPricing.originalPrice(
      widget.price,
      discount: widget.discount,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProductDetails(context),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: SizedBox(
                  height: 88,
                  child: ColoredBox(
                    color: imagePanelColor,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: AppImage(
                              source: widget.image,
                              fallbackType: AppImagePlaceholderType.product,
                              fit: BoxFit.cover,
                              cacheWidth: 320,
                              cacheHeight: 264,
                              filterQuality: FilterQuality.low,
                            ),
                          ),
                        ),
                        if (discount != null)
                          PositionedDirectional(
                            top: 8,
                            start: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                discount,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child:
                              BlocSelector<
                                WishlistCubit,
                                List<WishlistItem>,
                                bool
                              >(
                                selector: (items) => items.any(
                                  (element) =>
                                      element.productId == _resolvedProductId,
                                ),
                                builder: (context, isFavorite) {
                                  return _ProductIconButton(
                                    key: ValueKey(
                                      'product_wishlist_$_resolvedProductId',
                                    ),
                                    icon: isFavorite
                                        ? AppIcons.heart5
                                        : AppIcons.heart,
                                    iconColor: isFavorite
                                        ? AppColors.error
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black45),
                                    isDark: isDark,
                                    onTap: () =>
                                        _toggleWishlist(context, isFavorite),
                                  );
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        context.tr(widget.title),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          height: 1.18,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              context.tr(widget.brand),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: mutedColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            AppIcons.verify5,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _ProductPriceBlock(
                        price: displayedPrice,
                        oldPrice: originalPrice.isNotEmpty
                            ? originalPrice
                            : _formatPrice(widget.oldPrice),
                        textColor: textColor,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 4),
                      BlocSelector<CartCubit, List<CartItemData>, int>(
                        selector: (items) {
                          final cartItem = items
                              .where(
                                (i) =>
                                    (_resolvedVariantId != null &&
                                        i.variantId == _resolvedVariantId) ||
                                    i.productId == widget.productId ||
                                    i.id == _resolvedCartItemId,
                              )
                              .firstOrNull;
                          return cartItem?.quantity ?? 0;
                        },
                        builder: (context, currentQuantity) {
                          return _AddToCartButton(
                            key: ValueKey(
                              'product_add_to_cart_$_resolvedProductId',
                            ),
                            quantity: currentQuantity,
                            onTap: () => _addToCart(context),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPriceBlock extends StatelessWidget {
  const _ProductPriceBlock({
    required this.price,
    required this.oldPrice,
    required this.textColor,
    required this.mutedColor,
  });

  final String price;
  final String oldPrice;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 20,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GreenCurrencyPrice(
              price: price,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (oldPrice.isNotEmpty) ...[
              const SizedBox(width: 6),
              AppCurrencyText(
                text: oldPrice,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: mutedColor,
                  fontSize: 10,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductIconButton extends StatelessWidget {
  const _ProductIconButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? Colors.black.withValues(alpha: 0.28)
          : Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: iconColor, size: 18),
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({
    super.key,
    required this.quantity,
    required this.onTap,
  });

  final int quantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('Add to cart'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 3),
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Center(
                      child: quantity == 0
                          ? const Icon(
                              AppIcons.add,
                              color: Colors.white,
                              size: 14,
                            )
                          : Text(
                              '$quantity',
                              key: ValueKey('cart_quantity_$quantity'),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 11,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
