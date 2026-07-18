part of 'product_detail_view.dart';

class _PriceHeader extends StatelessWidget {
  const _PriceHeader({
    required this.discount,
    required this.price,
    required this.oldPrice,
    required this.isDark,
  });

  final String? discount;
  final String price;
  final String oldPrice;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final priceFill = isDark
        ? AppColors.primary.withValues(alpha: 0.14)
        : AppColors.primary.withValues(alpha: 0.08);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.14);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (discount != null) ...[
            _PriceDiscountBadge(discount: discount!),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: priceFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: GreenCurrencyPrice(
                        price: price,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: AppFontSizes.subtitle,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  if (oldPrice.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    SizedBox(
                      width: double.infinity,
                      height: 18,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: AppCurrencyText(
                          text: oldPrice,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceDiscountBadge extends StatelessWidget {
  const _PriceDiscountBadge({required this.discount});

  final String discount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          discount,
          style: const TextStyle(
            color: Colors.black,
            fontSize: AppFontSizes.label,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          context.tr(label),
          style: TextStyle(
            color: color,
            fontSize: AppFontSizes.label,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.brand, required this.isDark});

  final String brand;
  final bool isDark;

  void _openCategory(BuildContext context) {
    final shop = _shopForBrand();
    if (shop != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.brandProducts,
        arguments: BrandProductsRouteArgs(
          brand: shop.categoryName,
          logo: shop.logo,
          productCount: shop.productCountLabel,
          shopId: shop.id,
        ),
      );
      return;
    }

    final category = _categoryForBrand();
    final loadedCategory = _loadedCategory(context);

    Navigator.pushNamed(
      context,
      AppRoutes.brandProducts,
      arguments: BrandProductsRouteArgs(
        brand: loadedCategory?.name ?? category?.name ?? brand,
        logo:
            loadedCategory?.image ??
            category?.image ??
            AppAssets.temporaryMarketPlaceholder,
        productCount:
            loadedCategory?.productCountLabel ??
            category?.count ??
            '0 products',
      ),
    );
  }

  MarketShopData? _shopForBrand() {
    if (!AppEnvironment.useDemoRepositories) return null;

    final normalizedBrand = _normalize(brand);

    for (final shop in MarketShops.all) {
      if (_normalize(shop.name) == normalizedBrand) return shop;
    }

    return null;
  }

  MarketCategoryData? _categoryForBrand() {
    if (!AppEnvironment.useDemoRepositories) return null;

    final normalizedBrand = _normalize(brand);

    for (final category in MarketCategories.all) {
      if (_normalize(category.name) == normalizedBrand) return category;
    }

    return null;
  }

  CategoryData? _loadedCategory(BuildContext context) {
    final normalizedBrand = _normalize(brand);
    final discoveryState = context.read<ProductDiscoveryCubit>().state;

    for (final category in discoveryState.categories) {
      if (_normalize(category.name) == normalizedBrand) return category;
    }

    return null;
  }

  String _normalize(String value) => value.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _openCategory(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(brand),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 5),
              const Icon(AppIcons.verify5, color: AppColors.primary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(title),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.isDark,
    required this.title,
    required this.child,
  });

  final bool isDark;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(title),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
