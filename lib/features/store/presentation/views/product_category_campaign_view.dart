import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../core/presentation/widgets/products/product_results_view.dart';
import '../cubit/product_catalog_cubit.dart';
import '../cubit/product_catalog_state.dart';
import '../../domain/entities/product_data.dart';

class ProductCategoryCampaignView extends StatelessWidget {
  const ProductCategoryCampaignView({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: Text(categoryName.isEmpty ? 'منتجات التصنيف' : categoryName),
        centerTitle: true,
      ),
      body: BlocBuilder<ProductCatalogCubit, ProductCatalogState>(
        builder: (context, state) {
          final products = state is ProductCatalogReady
              ? state.products
                    .where((product) => product.categoryId == categoryId)
                    .toList(growable: false)
              : const <ProductData>[];
          final status = switch (state) {
            ProductCatalogLoading() ||
            ProductCatalogInitial() => ProductResultsStatus.loading,
            ProductCatalogFailure() => ProductResultsStatus.error,
            ProductCatalogNeedsCity() => ProductResultsStatus.empty,
            _ => ProductResultsStatus.ready,
          };
          return AppRefreshIndicator(
            onRefresh: () =>
                context.read<ProductCatalogCubit>().loadProducts(force: true),
            child: SingleChildScrollView(
              physics: AppRefreshIndicator.scrollPhysics,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: ProductResultsView(
                products: products,
                status: status,
                initialSortOption: 'Newest',
                onRetry: () => context.read<ProductCatalogCubit>().loadProducts(
                  force: true,
                ),
                errorMessage: state is ProductCatalogFailure
                    ? state.message
                    : 'تعذر تحميل المنتجات.',
                emptyTitle: 'لا توجد منتجات متاحة',
                emptyMessage:
                    'لا توجد منتجات متاحة في هذا التصنيف لمنطقتك حاليًا.',
              ),
            ),
          );
        },
      ),
    );
  }
}
