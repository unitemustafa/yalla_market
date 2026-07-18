import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/appbar/app_navigation_icon_button.dart';
import '../../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../../core/presentation/widgets/products/product_results_view.dart';
import '../../../../../core/routing/app_route_arguments.dart';
import '../../../../home/presentation/cubit/home_cubit.dart';
import '../../../../home/presentation/cubit/home_state.dart';
import '../../../domain/entities/product_data.dart';
import '../../cubit/product_catalog_cubit.dart';
import '../../cubit/product_catalog_state.dart';

class AllProductsView extends StatefulWidget {
  const AllProductsView({
    super.key,
    this.title = 'Popular Products',
    this.subtitle = 'Browse all curated products',
    this.collection = ProductCollectionType.popular,
    this.maxItems,
  });

  final String title;
  final String subtitle;
  final ProductCollectionType collection;
  final int? maxItems;

  @override
  State<AllProductsView> createState() => _AllProductsViewState();
}

class _AllProductsViewState extends State<AllProductsView> {
  @override
  void initState() {
    super.initState();
    if (widget.collection == ProductCollectionType.popular) {
      context.read<HomeCubit>().loadHome();
    }
  }

  List<ProductData> _limited(List<ProductData> products) {
    final maxItems = widget.maxItems;
    if (maxItems == null || maxItems >= products.length) return products;
    return products
        .take(maxItems.clamp(0, products.length))
        .toList(growable: false);
  }

  Future<void> _refreshProducts() {
    return switch (widget.collection) {
      ProductCollectionType.popular => context.read<HomeCubit>().loadHome(
        force: true,
      ),
      ProductCollectionType.latest =>
        context.read<ProductCatalogCubit>().loadProducts(force: true),
    };
  }

  Widget _buildProductResults() {
    return switch (widget.collection) {
      ProductCollectionType.popular => BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final products =
              state.data?.products
                  .where((product) => product.isPopular)
                  .toList(growable: false) ??
              const <ProductData>[];
          final status = switch (state) {
            HomeInitial() => ProductResultsStatus.loading,
            HomeLoading() when state.data == null =>
              ProductResultsStatus.loading,
            HomeFailure() when state.data == null => ProductResultsStatus.error,
            _ => ProductResultsStatus.ready,
          };

          return ProductResultsView(
            products: _limited(products),
            status: status,
            initialSortOption: 'Newest',
            onRetry: () => context.read<HomeCubit>().loadHome(force: true),
            errorMessage: state is HomeFailure
                ? state.message
                : 'Please check your connection and try again.',
            emptyTitle: 'No products available',
            emptyMessage:
                'Products will appear here once the catalog is ready.',
          );
        },
      ),
      ProductCollectionType.latest =>
        BlocBuilder<ProductCatalogCubit, ProductCatalogState>(
          builder: (context, state) {
            final products = state is ProductCatalogReady
                ? _limited(state.products)
                : const <ProductData>[];
            final status = switch (state) {
              ProductCatalogLoading() => ProductResultsStatus.loading,
              ProductCatalogFailure() => ProductResultsStatus.error,
              ProductCatalogNeedsCity() => ProductResultsStatus.empty,
              _ => ProductResultsStatus.ready,
            };

            return ProductResultsView(
              products: products,
              status: status,
              initialSortOption: 'Newest',
              onRetry: () =>
                  context.read<ProductCatalogCubit>().loadProducts(force: true),
              errorMessage: state is ProductCatalogFailure
                  ? state.message
                  : 'Please check your connection and try again.',
              emptyTitle: 'No products available',
              emptyMessage: state is ProductCatalogNeedsCity
                  ? 'So we can show products available in your area.'
                  : 'Products will appear here once the catalog is ready.',
            );
          },
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = constraints.maxWidth >= 800
                ? 920.0
                : constraints.maxWidth;

            return AppRefreshIndicator(
              onRefresh: _refreshProducts,
              child: SingleChildScrollView(
                physics: AppRefreshIndicator.scrollPhysics,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProductsTopBar(
                          title: widget.title,
                          subtitle: widget.subtitle,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                        _buildProductResults(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductsTopBar extends StatelessWidget {
  const _ProductsTopBar({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        AppNavigationIconButton.back(onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(title),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: AppFontSizes.subtitle,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                context.tr(subtitle),
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
    );
  }
}
