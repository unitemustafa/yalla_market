part of 'wishlist_view.dart';

String _wishlistProductId(WishlistItem item) => item.productId;
ProductCardTileData _wishlistProductCardData(WishlistItem item) =>
    ProductCardTileData(
      id: item.productId,
      image: item.image,
      title: item.title,
      brand: item.brand,
      price: item.price,
      oldPrice: item.oldPrice,
      discount: item.discount,
    );

class _WishlistSectionTitle extends StatelessWidget {
  const _WishlistSectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 9),
        Text(
          context.tr(title),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _WishlistTopBar extends StatelessWidget {
  const _WishlistTopBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Wishlist'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('Saved products and stores'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: CartCounterIcon(
            iconColor: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyWishlistView extends StatelessWidget {
  const _EmptyWishlistView({
    required this.isDark,
    required this.onExplorePressed,
  });

  final bool isDark;
  final VoidCallback onExplorePressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitleColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: AppRefreshIndicator.scrollPhysics,
            child: Column(
              children: [
                const AppRefreshAnchor(),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _WishlistEmptyArtwork(isDark: isDark),
                        const SizedBox(height: 28),
                        Text(
                          context.tr('Your wishlist is waiting'),
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr(
                            'Save the products you love and find them here whenever you are ready.',
                          ),
                          style: textTheme.bodyMedium?.copyWith(
                            color: subtitleColor,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: AppActionButton(
                            label: 'Explore products',
                            icon: AppIcons.shop,
                            onPressed: onExplorePressed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WishlistEmptyArtwork extends StatelessWidget {
  const _WishlistEmptyArtwork({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final panelColor = isDark ? const Color(0xFF262838) : Colors.white;
    final panelBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.10);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.22)
        : AppColors.primary.withValues(alpha: 0.10);

    return SizedBox(
      width: 260,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 12,
            child: Container(
              width: 230,
              height: 142,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: panelBorder),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ProductPeek(
                      image: AppAssets.nikeAirJordanSingleBlue,
                      backgroundColor: Color(0xFFEAF2FF),
                      angle: -0.12,
                    ),
                    SizedBox(width: 8),
                    _ProductPeek(
                      image: AppAssets.samsungS9Mobile,
                      backgroundColor: Color(0xFFFFF2DD),
                      angle: 0.08,
                    ),
                    SizedBox(width: 8),
                    _ProductPeek(
                      image: AppAssets.leatherJacket1,
                      backgroundColor: Color(0xFFEFF8F1),
                      angle: 0.12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: const Icon(AppIcons.heart5, size: 48, color: Colors.white),
            ),
          ),
          PositionedDirectional(
            end: 68,
            bottom: 22,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkCardColor : Colors.white,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                AppIcons.add,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPeek extends StatelessWidget {
  const _ProductPeek({
    required this.image,
    required this.backgroundColor,
    required this.angle,
  });

  final String image;
  final Color backgroundColor;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 58,
        height: 78,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: AppImage(
          source: image,
          fallbackType: AppImagePlaceholderType.product,
          fit: BoxFit.contain,
          cacheWidth: 116,
          cacheHeight: 156,
        ),
      ),
    );
  }
}

class _FavoriteLoadMore extends StatelessWidget {
  const _FavoriteLoadMore({
    super.key,
    required this.loading,
    this.error,
    required this.onPressed,
  });
  final bool loading;
  final String? error;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      children: [
        if (error != null) Text(context.tr(error!)),
        TextButton(
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr(error == null ? 'Load more' : 'Try again')),
        ),
      ],
    ),
  );
}
