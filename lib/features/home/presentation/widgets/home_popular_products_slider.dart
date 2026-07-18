import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../store/domain/entities/product_data.dart';
import '../../../store/presentation/cubit/product_catalog_cubit.dart';
import '../../../store/presentation/cubit/product_catalog_state.dart';

enum HomeProductsSliderMode { popular, latest }

class HomeProductsSlider extends StatelessWidget {
  const HomeProductsSlider({
    super.key,
    required this.onViewAll,
    this.products,
    this.limit = 5,
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
      height: 188,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 8.0;
          final cardWidth = ((constraints.maxWidth - (spacing * 2)) / 3)
              .clamp(88.0, 112.0)
              .toDouble();

          return ListView.separated(
            key: ValueKey('${_keyPrefix}_products_horizontal_slider'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: visibleProducts.length + (showViewAll ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: spacing),
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
                child: ProductCardVertical(
                  image: product.image,
                  title: product.title,
                  brand: product.brand,
                  price: product.price,
                  productId: product.id,
                  productSlug: product.slug,
                  defaultVariantId: product.defaultVariantId,
                  marketId: product.marketId,
                  marketName: product.brand,
                  oldPrice: product.oldPrice,
                  discount: product.discount,
                ),
              );
            },
          );
        },
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
      width: 108,
      child: Material(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
