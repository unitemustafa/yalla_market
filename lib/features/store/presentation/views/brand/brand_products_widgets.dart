part of 'brand_products_view.dart';

// Kept temporarily for compatibility with older golden-test fixtures.
// ignore: unused_element
class _StorefrontHero extends StatelessWidget {
  const _StorefrontHero({
    required this.market,
    required this.onBack,
    required this.onSearch,
    required this.onShare,
    required this.onCart,
  });

  final StoreMarketData market;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onShare;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    MarketWishlistCubit? marketWishlistCubit;
    try {
      marketWishlistCubit = context.read<MarketWishlistCubit>();
    } on Object {
      marketWishlistCubit = null;
    }
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardColor = isDark ? AppColors.darkCardColor : Colors.white;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final delivery = market.deliveryTimeMinMinutes == null
        ? null
        : market.deliveryTimeMinMinutes == market.deliveryTimeMaxMinutes
        ? '${market.deliveryTimeMinMinutes} ${arabic ? 'دقيقة' : 'min'}'
        : '${market.deliveryTimeMinMinutes}-${market.deliveryTimeMaxMinutes} '
              '${arabic ? 'دقيقة' : 'min'}';
    final minimumPrice = market.minimumProductPrice;

    return SizedBox(
      key: const ValueKey('storefront_hero'),
      height: 370,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: 118,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    source: market.coverImage,
                    fallbackType: AppImagePlaceholderType.store,
                    fit: BoxFit.cover,
                    cacheWidth: 1080,
                    cacheHeight: 620,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.42),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 12,
            start: 12,
            end: 12,
            child: Row(
              children: [
                _HeroActionButton(
                  key: const ValueKey('storefront_back_button'),
                  icon: Directionality.of(context) == TextDirection.rtl
                      ? AppIcons.arrow_right_3
                      : AppIcons.arrow_left_2,
                  onTap: onBack,
                ),
                const Spacer(),
                _HeroActionButton(
                  key: const ValueKey('storefront_search_button'),
                  icon: AppIcons.search_normal,
                  onTap: onSearch,
                ),
                const SizedBox(width: 7),
                _HeroActionButton(
                  key: const ValueKey('storefront_share_button'),
                  icon: AppIcons.send_1,
                  onTap: onShare,
                ),
                const SizedBox(width: 7),
                if (marketWishlistCubit == null)
                  _HeroActionButton(
                    key: const ValueKey('storefront_favorite_button'),
                    icon: market.isLiked ? AppIcons.heart5 : AppIcons.heart,
                    iconColor: market.isLiked ? AppColors.error : null,
                  )
                else
                  BlocBuilder<MarketWishlistCubit, MarketWishlistState>(
                    bloc: marketWishlistCubit,
                    buildWhen: (previous, current) =>
                        previous.items != current.items ||
                        previous.busyIds != current.busyIds,
                    builder: (context, state) {
                      final cubit = marketWishlistCubit!;
                      final favorite = cubit.isFavorite(market);
                      return _HeroActionButton(
                        key: const ValueKey('storefront_favorite_button'),
                        icon: favorite ? AppIcons.heart5 : AppIcons.heart,
                        iconColor: favorite ? AppColors.error : null,
                        onTap: state.busyIds.contains(market.id)
                            ? null
                            : () => toggleMarketFavoriteWithFeedback(
                                context: context,
                                cubit: cubit,
                                market: market,
                              ),
                      );
                    },
                  ),
                const SizedBox(width: 7),
                _HeroActionButton(
                  key: const ValueKey('storefront_cart_button'),
                  child: CartCounterIcon(
                    onPressed: onCart,
                    iconColor: AppColors.lightTextPrimary,
                    iconSize: 19,
                    buttonSize: 42,
                  ),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            top: 176,
            start: 12,
            end: 12,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.16),
                          ),
                        ),
                        child: AppImage(
                          source: market.image,
                          fallbackType: AppImagePlaceholderType.store,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(14),
                          cacheWidth: 160,
                          cacheHeight: 160,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              market.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            if (market.description.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                market.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: mutedColor, height: 1.35),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (delivery != null)
                        _StorefrontMetaChip(
                          icon: AppIcons.truck_fast,
                          label: delivery,
                        ),
                      _StorefrontMetaChip(
                        icon: AppIcons.box,
                        label:
                            '${market.effectiveProductCount} '
                            '${arabic ? 'منتج' : 'products'}',
                      ),
                      if (minimumPrice != null)
                        _StorefrontMetaChip(
                          icon: AppIcons.money_3,
                          label:
                              '${arabic ? 'يبدأ من' : 'Starts from'} '
                              '${AppCurrency.format(minimumPrice)}',
                          emphasized: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    super.key,
    this.icon,
    this.iconColor,
    this.onTap,
    this.child,
  });

  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child:
              child ??
              Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.lightTextPrimary,
              ),
        ),
      ),
    );
  }
}

class _StorefrontMetaChip extends StatelessWidget {
  const _StorefrontMetaChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized ? AppColors.primary : Theme.of(context).hintColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.primary.withValues(alpha: 0.10)
            : Theme.of(context).dividerColor.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreOfferSection extends StatelessWidget {
  const _StoreOfferSection({required this.offers});

  final List<OfferData> offers;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('store_offer_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Offers'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        PromoSlider(offers: offers),
      ],
    );
  }
}

class _StoreSubcategoryRail extends StatelessWidget {
  const _StoreSubcategoryRail({
    required this.categories,
    required this.selectedId,
    required this.languageCode,
    required this.categoryDescription,
    required this.onSelected,
  });

  final List<StoreSubcategoryData> categories;
  final String? selectedId;
  final String languageCode;
  final String? categoryDescription;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: SizedBox(
            height: 47,
            child: ListView.separated(
              key: const ValueKey('store_subcategory_rail'),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final category = index == 0 ? null : categories[index - 1];
                final isSelected = category?.id == selectedId;
                final label = category == null
                    ? (languageCode.startsWith('ar') ? 'الكل' : 'All')
                    : category.localizedName(languageCode);
                return InkWell(
                  key: ValueKey(
                    category == null
                        ? 'store_subcategory_all'
                        : 'store_subcategory_${category.id}',
                  ),
                  onTap: () => onSelected(category?.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (category == null) ...[
                          Icon(
                            AppIcons.category,
                            size: 16,
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.1,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (categoryDescription?.isNotEmpty == true) ...[
          const SizedBox(height: 7),
          Text(
            categoryDescription!,
            key: const ValueKey('store_subcategory_description'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _LocalCategoryHeader extends StatelessWidget {
  const _LocalCategoryHeader({
    required this.title,
    required this.logo,
    required this.cityName,
    required this.shopCount,
  });

  final String title;
  final String logo;
  final String cityName;
  final int shopCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppImage(
              source: logo,
              fallbackType: AppImagePlaceholderType.store,
              fit: BoxFit.contain,
              cacheWidth: 108,
              cacheHeight: 108,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  shopCount == 0
                      ? 'لا يوجد محلات متاحة في $cityName'
                      : '$shopCount محل متاح في $cityName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalShopCard extends StatelessWidget {
  const _LocalShopCard({required this.shop, required this.onTap});

  final MarketShopData shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEDEFF3);
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : const Color(0xFF9B9B9B);
    final accentColor = Color(shop.accentColorValue);
    final previewColor = isDark
        ? accentColor.withValues(alpha: 0.16)
        : const Color(0xFFFDEDEE);
    final forwardIcon = Directionality.of(context) == TextDirection.rtl
        ? AppIcons.arrow_left_2
        : AppIcons.arrow_right_3;
    final previewProducts = shop.products.take(3).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.055),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _ShopLogo(
                      shop: shop,
                      size: 58,
                      backgroundColor: previewColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            shop.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w900,
                                  height: 1.08,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          _ShopMetaChip(
                            icon: AppIcons.box,
                            label: shop.productCountLabel,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        forwardIcon,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: previewProducts
                      .map(
                        (product) => Expanded(
                          child: _ShopPreviewTile(
                            image: product.image,
                            backgroundColor: previewColor,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    previewProducts.map((product) => product.title).join(' • '),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopPreviewTile extends StatelessWidget {
  const _ShopPreviewTile({required this.image, required this.backgroundColor});

  final String image;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: 82,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AppImage(
          source: image,
          fallbackType: AppImagePlaceholderType.product,
          fit: BoxFit.contain,
          cacheWidth: 164,
          cacheHeight: 164,
        ),
      ),
    );
  }
}

class _ShopLogo extends StatelessWidget {
  const _ShopLogo({
    required this.shop,
    required this.size,
    this.backgroundColor,
  });

  final MarketShopData shop;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Color(shop.accentColorValue);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AppImage(
        source: shop.logo,
        fallbackType: AppImagePlaceholderType.store,
        fit: BoxFit.contain,
        cacheWidth: (size * 2).round(),
        cacheHeight: (size * 2).round(),
      ),
    );
  }
}

class _ShopMetaChip extends StatelessWidget {
  const _ShopMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            context.tr(label),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketTypeRail extends StatelessWidget {
  const _MarketTypeRail({
    required this.classificationImage,
    required this.types,
    required this.selectedId,
    required this.onSelected,
  });

  final String classificationImage;
  final List<StoreMarketTypeData> types;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isArabic = languageCode.toLowerCase().startsWith('ar');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'اختار نوع المحل' : 'Choose by type',
          key: const ValueKey('market_type_heading'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.separated(
            key: const ValueKey('market_type_rail'),
            scrollDirection: Axis.horizontal,
            itemCount: types.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final type = index == 0 ? null : types[index - 1];
              final id = type?.id;
              return _MarketTypeItem(
                key: ValueKey(
                  id == null ? 'market_type_all' : 'market_type_$id',
                ),
                label:
                    type?.localizedName(languageCode) ??
                    (isArabic ? 'الكل' : 'All'),
                image: type?.image ?? classificationImage,
                selected: selectedId == id,
                onTap: () => onSelected(id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MarketTypeItem extends StatelessWidget {
  const _MarketTypeItem({
    super.key,
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(42),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 68,
                height: 68,
                padding: EdgeInsets.all(selected ? 3 : 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? colors.primary.withValues(alpha: 0.10)
                      : colors.surfaceContainerHighest,
                  border: Border.all(
                    color: selected
                        ? colors.primary
                        : colors.outlineVariant.withValues(alpha: 0.55),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: ClipOval(
                  child: AppImage(
                    source: image,
                    width: 62,
                    height: 62,
                    fit: BoxFit.cover,
                    fallbackType: AppImagePlaceholderType.category,
                    cacheWidth: 136,
                    cacheHeight: 136,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? colors.primary : colors.onSurface,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
