import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/formatters/app_currency.dart';
import '../../../../core/formatters/product_pricing.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../../../core/presentation/widgets/texts/green_currency_price.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../store/domain/entities/product_data.dart';
import '../../../store/presentation/cubit/product_catalog_cubit.dart';
import '../../../store/presentation/cubit/product_catalog_state.dart';
import '../../../wishlist/domain/entities/wishlist_item.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';

enum HomeProductsSliderMode { popular, latest }

class HomeProductsSlider extends StatelessWidget {
  const HomeProductsSlider({
    super.key,
    required this.onViewAll,
    this.products,
    this.limit = 6,
    this.mode = HomeProductsSliderMode.popular,
  });

  final List<ProductData>? products;
  final int limit;
  final HomeProductsSliderMode mode;
  final VoidCallback onViewAll;

  String get _keyPrefix => switch (mode) {
    HomeProductsSliderMode.popular => 'popular',
    HomeProductsSliderMode.latest => 'latest',
  };

  @override
  Widget build(BuildContext context) {
    var loadedProducts = const <ProductData>[];
    if (products == null) {
      final catalogState = context.watch<ProductCatalogCubit>().state;
      if (catalogState is ProductCatalogLoading) {
        return const AppLoadingState(message: 'Loading products...');
      }
      if (catalogState is ProductCatalogFailure) {
        return AppErrorState(
          title: 'Products could not load',
          message: catalogState.message,
          onRetry: () =>
              context.read<ProductCatalogCubit>().loadProducts(force: true),
        );
      }
      if (catalogState is ProductCatalogNeedsCity) {
        return const AppEmptyState(
          title: 'Choose your city',
          message: 'So we can show products available in your area.',
        );
      }
      if (catalogState is ProductCatalogReady) {
        loadedProducts = catalogState.products;
      }
    }

    final source = products ?? loadedProducts;
    final matchingProducts = switch (mode) {
      HomeProductsSliderMode.popular =>
        source.where((product) => product.isPopular).toList(growable: false),
      HomeProductsSliderMode.latest => source,
    };
    final visibleProducts = matchingProducts
        .take(limit.clamp(0, matchingProducts.length))
        .toList(growable: false);
    final showViewAll = matchingProducts.length > visibleProducts.length;

    if (visibleProducts.isEmpty) {
      return const AppEmptyState(
        title: 'No products available',
        message: 'Products will appear here once the catalog is ready.',
      );
    }

    return SizedBox(
      height: 144,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth * 0.86)
              .clamp(286.0, 352.0)
              .toDouble();

          return ListView.separated(
            key: ValueKey('${_keyPrefix}_products_horizontal_slider'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: visibleProducts.length + (showViewAll ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (showViewAll && index == visibleProducts.length) {
                return _ViewAllProductsCard(
                  keyPrefix: _keyPrefix,
                  onTap: onViewAll,
                );
              }

              final product = visibleProducts[index];
              return SizedBox(
                key: ValueKey('${_keyPrefix}_product_${product.id}'),
                width: cardWidth,
                child: _HorizontalProductCard(product: product),
              );
            },
          );
        },
      ),
    );
  }
}

class _HorizontalProductCard extends StatefulWidget {
  const _HorizontalProductCard({required this.product});

  final ProductData product;

  @override
  State<_HorizontalProductCard> createState() => _HorizontalProductCardState();
}

class _HorizontalProductCardState extends State<_HorizontalProductCard> {
  ProductData get product => widget.product;

  String? get _variantId {
    final value = product.defaultVariantId?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String get _cartItemId => _variantId ?? product.id;

  void _openDetails() {
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: ProductDetailRouteArgs(
        image: product.image,
        title: product.title,
        brand: product.brand,
        price: product.price,
        productId: product.id,
        productSlug: product.slug,
        oldPrice: product.oldPrice,
        discount: product.discount,
      ),
    );
  }

  void _toggleWishlist(bool wasFavorite) {
    final displayedPrice = ProductPricing.formattedPrice(
      product.price,
      discount: product.discount,
    );
    final originalPrice = ProductPricing.originalPrice(
      product.price,
      discount: product.discount,
    );
    final discount = ProductPricing.discountLabel(product.discount);

    context.read<WishlistCubit>().toggleItem(
      WishlistItem(
        productId: product.id,
        image: product.image,
        title: product.title,
        brand: product.brand,
        price: displayedPrice,
        oldPrice: originalPrice.isNotEmpty ? originalPrice : product.oldPrice,
        discount: discount == null
            ? null
            : (context.isArabicLanguage ? 'خصم $discount' : '$discount OFF'),
      ),
    );

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

  void _addToCart() {
    context.read<CartCubit>().addItem(
      CartItemData(
        id: _cartItemId,
        productId: product.id,
        variantId: _variantId,
        marketId: product.marketId,
        marketName: product.brand,
        image: product.image,
        brand: product.brand,
        title: product.title,
        price: ProductPricing.firstPrice(
          product.price,
          discount: product.discount,
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
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final discount = ProductPricing.discountLabel(product.discount);
    final displayedPrice = ProductPricing.formattedPrice(
      product.price,
      discount: product.discount,
    );
    final originalPrice = ProductPricing.originalPrice(
      product.price,
      discount: product.discount,
    );
    final fallbackOldPrice = AppCurrency.formatPriceText(product.oldPrice);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openDetails,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(10),
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
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadiusDirectional.horizontal(
                  start: Radius.circular(10),
                ),
                child: SizedBox(
                  width: 106,
                  height: double.infinity,
                  child: ColoredBox(
                    color: imagePanelColor,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: AppImage(
                              source: product.image,
                              fallbackType: AppImagePlaceholderType.product,
                              fit: BoxFit.cover,
                              cacheWidth: 300,
                              cacheHeight: 360,
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
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                context.isArabicLanguage
                                    ? 'خصم $discount'
                                    : '$discount OFF',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(product.title),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: textColor,
                                    height: 1.18,
                                    fontWeight: FontWeight.w900,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    context.tr(product.brand),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: mutedColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                            const Spacer(),
                            _HorizontalPriceBlock(
                              price: displayedPrice,
                              oldPrice: originalPrice.isNotEmpty
                                  ? originalPrice
                                  : fallbackOldPrice,
                              textColor: textColor,
                              mutedColor: mutedColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BlocSelector<WishlistCubit, List<WishlistItem>, bool>(
                            selector: (items) => items.any(
                              (item) => item.productId == product.id,
                            ),
                            builder: (context, isFavorite) {
                              return _SmallIconButton(
                                key: ValueKey(
                                  'horizontal-product-wishlist-${product.id}',
                                ),
                                icon: isFavorite
                                    ? AppIcons.heart5
                                    : AppIcons.heart,
                                iconColor: isFavorite
                                    ? AppColors.error
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black45),
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF1F3F8),
                                onTap: () => _toggleWishlist(isFavorite),
                              );
                            },
                          ),
                          BlocSelector<CartCubit, List<CartItemData>, int>(
                            selector: (items) {
                              final matchingItems = items.where(
                                (item) =>
                                    (_variantId != null &&
                                        item.variantId == _variantId) ||
                                    item.productId == product.id ||
                                    item.id == _cartItemId,
                              );
                              return matchingItems.isEmpty
                                  ? 0
                                  : matchingItems.first.quantity;
                            },
                            builder: (context, quantity) {
                              return _SmallAddToCartButton(
                                key: ValueKey(
                                  'horizontal-product-add-${product.id}',
                                ),
                                quantity: quantity,
                                onTap: _addToCart,
                              );
                            },
                          ),
                        ],
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

class _HorizontalPriceBlock extends StatelessWidget {
  const _HorizontalPriceBlock({
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: GreenCurrencyPrice(
            price: price,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (oldPrice.isNotEmpty) ...[
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: AppCurrencyText(
              text: oldPrice,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: mutedColor,
                fontSize: 10,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, color: iconColor, size: 17),
        ),
      ),
    );
  }
}

class _SmallAddToCartButton extends StatelessWidget {
  const _SmallAddToCartButton({
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
          width: 36,
          height: 36,
          child: Center(
            child: quantity == 0
                ? const Icon(AppIcons.add, color: Colors.white, size: 19)
                : Text(
                    context.tr('$quantity'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ViewAllProductsCard extends StatelessWidget {
  const _ViewAllProductsCard({required this.keyPrefix, required this.onTap});

  final String keyPrefix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SizedBox(
      key: ValueKey('${keyPrefix}_products_view_all'),
      width: 92,
      child: Material(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('View all'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
