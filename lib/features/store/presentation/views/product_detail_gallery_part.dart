part of 'product_detail_view.dart';

extension _ProductDetailHeader on _ProductDetailViewState {
  double _productToolbarHeight(BuildContext context) => math.max(
    kToolbarHeight,
    MediaQuery.textScalerOf(context).scale(16) * 1.4 + 16,
  );

  SliverAppBar _buildProductHeader({
    required bool isDark,
    required List<String> thumbnailImages,
    required double width,
    required double toolbarHeight,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleLarge!.copyWith(
      color: isDark ? Colors.white : AppColors.lightTextPrimary,
      fontSize: AppFontSizes.title,
      height: 1.12,
      fontWeight: FontWeight.w900,
    );
    final horizontalInsets = MediaQuery.paddingOf(context).horizontal;
    final titlePainter = TextPainter(
      text: TextSpan(text: context.tr(_productTitle), style: titleStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: math.max(1, width - horizontalInsets - 32));
    final titleHeight = titlePainter.height;
    titlePainter.dispose();

    return SliverAppBar(
      key: const ValueKey('product_detail_header'),
      pinned: true,
      stretch: true,
      toolbarHeight: toolbarHeight,
      expandedHeight: toolbarHeight + 286 + titleHeight + 16,
      automaticallyImplyLeading: false,
      backgroundColor: isDark
          ? AppColors.darkCardColor
          : const Color(0xFFF1F3F8),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leadingWidth: 74,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        child: Center(
          child: AnimatedBuilder(
            animation: _cartAnimation,
            builder: (context, child) {
              final pulse = ((_cartAnimation.value * 880 - 700) / 180).clamp(
                0.0,
                1.0,
              );
              return Transform.scale(
                key: const ValueKey('product_detail_cart_scale'),
                scale: 1 + 0.18 * math.sin(math.pi * pulse),
                child: child,
              );
            },
            child: Tooltip(
              message: context.tr('Cart'),
              child: Material(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: SizedBox(
                  key: _cartTargetKey,
                  width: 42,
                  height: 42,
                  child: CartCounterIcon(
                    onPressed: _openCart,
                    iconColor: isDark ? Colors.white : Colors.black,
                    iconSize: 21,
                    buttonSize: 42,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsetsDirectional.only(end: 16),
      actions: [
        _CircleActionButton(
          icon: AppIcons.send_1,
          isDark: isDark,
          onTap: _showProductShareSheet,
          tooltip: 'Share product',
        ),
        const SizedBox(width: 8),
        BlocSelector<WishlistCubit, List<WishlistItem>, bool>(
          selector: (items) => items is WishlistState
              ? items.containsProduct(_resolvedProductId)
              : items.any((item) => item.productId == _resolvedProductId),
          builder: (context, isFavorite) => _CircleActionButton(
            icon: isFavorite ? AppIcons.heart5 : AppIcons.heart,
            color: isFavorite ? AppColors.error : null,
            isDark: isDark,
            onTap: () => _toggleWishlist(context, isFavorite),
          ),
        ),
      ],
      flexibleSpace: _ProductFlexibleHeader(
        title: context.tr(_productTitle),
        titleStyle: titleStyle,
        expandedTitleHeight: titleHeight,
        toolbarHeight: toolbarHeight,
        gallery: _ProductGallery(
          isDark: isDark,
          currentImage: currentImage,
          thumbnailImages: thumbnailImages,
          imageKey: _productImageKey,
          onImageTap: () => _showImageDialog(context, currentImage),
          onThumbnailTap: (asset) => _updateState(() => currentImage = asset),
        ),
      ),
    );
  }
}

class _ProductFlexibleHeader extends StatelessWidget {
  const _ProductFlexibleHeader({
    required this.title,
    required this.titleStyle,
    required this.expandedTitleHeight,
    required this.toolbarHeight,
    required this.gallery,
  });

  final String title;
  final TextStyle titleStyle;
  final double expandedTitleHeight;
  final double toolbarHeight;
  final _ProductGallery gallery;

  @override
  Widget build(BuildContext context) {
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()!;
    final range = settings.maxExtent - settings.minExtent;
    final collapse = ((settings.maxExtent - settings.currentExtent) / range)
        .clamp(0.0, 1.0);
    final topInset = MediaQuery.paddingOf(context).top;
    final collapsedTitleHeight =
        MediaQuery.textScalerOf(context).scale(16) * 1.12;
    final titleHeight =
        expandedTitleHeight +
        (collapsedTitleHeight - expandedTitleHeight) * collapse;
    final start = 16 + 58 * collapse;
    final end = 16 + 100 * collapse;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stretch = math.max(
          0.0,
          constraints.maxHeight - settings.maxExtent,
        );
        final expandedTitleTop = settings.maxExtent - expandedTitleHeight - 16;
        final collapsedTitleTop =
            topInset + (toolbarHeight - collapsedTitleHeight) / 2;
        final titleTop =
            expandedTitleTop +
            (collapsedTitleTop - expandedTitleTop) * collapse +
            stretch;
        final galleryHeight = math.max(
          0.0,
          titleTop - topInset - toolbarHeight - 14,
        );

        return ClipRect(
          child: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                Positioned(
                  top: topInset + toolbarHeight,
                  left: 0,
                  right: 0,
                  height: galleryHeight,
                  child: IgnorePointer(
                    ignoring: collapse > 0.9,
                    child: ExcludeSemantics(
                      excluding: collapse > 0.9,
                      child: Opacity(opacity: 1 - collapse, child: gallery),
                    ),
                  ),
                ),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  top: titleTop,
                  start: start,
                  end: end,
                  height: titleHeight,
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      key: const ValueKey('product_detail_title'),
                      maxLines: collapse == 1 ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle.copyWith(
                        fontSize:
                            AppFontSizes.title +
                            (16 - AppFontSizes.title) * collapse,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductGallery extends StatelessWidget {
  const _ProductGallery({
    required this.isDark,
    required this.currentImage,
    required this.thumbnailImages,
    required this.imageKey,
    required this.onImageTap,
    required this.onThumbnailTap,
  });

  final bool isDark;
  final String currentImage;
  final List<String> thumbnailImages;
  final Key imageKey;
  final VoidCallback onImageTap;
  final ValueChanged<String> onThumbnailTap;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final imageLogicalWidth = (MediaQuery.sizeOf(context).width - 32).clamp(
      1.0,
      720.0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale the image in both axes; keep thumbnails undistorted and clip
        // their row as the gallery collapses.
        final scale = constraints.maxHeight / 272;
        final imageHeight = 188 * scale;
        final imageWidth = math.max(0.0, constraints.maxWidth - 32) * scale;
        final thumbnailHeight = math.min(64.0, 64 * scale);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(height: 8 * scale),
              GestureDetector(
                onTap: onImageTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: OverflowBox(
                      minWidth: imageWidth,
                      maxWidth: imageWidth,
                      minHeight: imageHeight,
                      maxHeight: imageHeight,
                      child: SizedBox(
                        key: imageKey,
                        height: imageHeight,
                        width: imageWidth,
                        child: AppImage(
                          key: const ValueKey('product_detail_main_image'),
                          source: currentImage,
                          fallbackType: AppImagePlaceholderType.product,
                          fit: BoxFit.contain,
                          cacheWidth: (imageLogicalWidth * devicePixelRatio)
                              .round(),
                          cacheHeight: (188 * devicePixelRatio).round(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
              SizedBox(
                height: thumbnailHeight,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: 64,
                    maxHeight: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: thumbnailImages.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final asset = thumbnailImages[index];
                        return _ThumbnailButton(
                          asset: asset,
                          isSelected: currentImage == asset,
                          isDark: isDark,
                          onTap: () => onThumbnailTap(asset),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: isDark
          ? Colors.black.withValues(alpha: 0.22)
          : Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 21,
            color: color ?? (isDark ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
    final message = tooltip;
    if (message == null) return button;
    return Tooltip(message: context.tr(message), child: button);
  }
}

class _ThumbnailButton extends StatelessWidget {
  const _ThumbnailButton({
    required this.asset,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String asset;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 64,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: AppImage(
          source: asset,
          fallbackType: AppImagePlaceholderType.product,
          fit: BoxFit.contain,
          cacheWidth: 128,
          cacheHeight: 128,
        ),
      ),
    );
  }
}
