import 'package:flutter/material.dart';

import '../../../../../core/presentation/widgets/states/app_skeleton.dart';
import '../../../../../core/presentation/widgets/states/app_state_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../home/presentation/cubit/home_cubit.dart';
import '../../../../home/presentation/cubit/home_state.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/brands/category_tile.dart';
import '../../../../../core/presentation/widgets/layouts/grid_layout.dart';
import '../../../../../core/presentation/widgets/texts/section_heading.dart';
import '../../../../../app/routing/app_route_arguments.dart';
import '../../../../../app/routing/app_routes.dart';
import '../../../domain/entities/category_data.dart';
import '../../cubit/product_discovery_cubit.dart';
import '../../cubit/product_discovery_state.dart';

@visibleForTesting
List<CategoryData> normalCategoriesForAllCategories(
  Iterable<CategoryData> categories,
) {
  return categories
      .where((category) => category.classificationType == 'normal')
      .toList(growable: false);
}

@visibleForTesting
List<CategoryData> categoriesForAllCategories({
  Iterable<CategoryData>? routedCategories,
  required Iterable<CategoryData> discoveryCategories,
}) {
  final routed = routedCategories?.toList(growable: false) ?? const [];
  if (routed.isNotEmpty) return routed;
  return normalCategoriesForAllCategories(discoveryCategories);
}

class BrandsView extends StatelessWidget {
  const BrandsView({super.key, this.categories});

  final List<CategoryData>? categories;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF7F8FB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    PageTopBar(
                      title: 'Categories',
                      subtitle: 'Explore market categories',
                    ),
                    SizedBox(height: 18),
                    SectionHeading(
                      title: 'All Categories',
                      showActionButton: false,
                      titleFontSize: AppFontSizes.pageTitle,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: categories?.isNotEmpty == true
                  ? BlocBuilder<HomeCubit, HomeState>(
                      builder: (context, state) => _AllCategoriesGrid(
                        categories: state.data?.categories ?? categories!,
                      ),
                    )
                  : BlocBuilder<ProductDiscoveryCubit, ProductDiscoveryState>(
                      builder: (context, state) {
                        if (state.categories.isNotEmpty) {
                          return SliverContentReveal(
                            child: _AllCategoriesGrid(
                              categories: categoriesForAllCategories(
                                discoveryCategories: state.categories,
                              ),
                            ),
                          );
                        }
                        if (state is ProductDiscoveryInitial ||
                            state is ProductDiscoveryLoading) {
                          return const SliverToBoxAdapter(
                            child: AppCategorySkeletonGrid(),
                          );
                        }
                        if (state is ProductDiscoveryFailure) {
                          return SliverToBoxAdapter(
                            child: AppErrorState(
                              title: 'Categories could not load',
                              message: state.message,
                              onRetry: () => context
                                  .read<ProductDiscoveryCubit>()
                                  .loadDiscovery(force: true),
                            ),
                          );
                        }
                        return SliverToBoxAdapter(
                          child: AppEmptyState(
                            title: state is ProductDiscoveryNeedsCity
                                ? 'Choose your city'
                                : 'No categories available',
                            message: state is ProductDiscoveryNeedsCity
                                ? 'So we can show categories available in your area.'
                                : 'Categories will appear here once the catalog is ready.',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllCategoriesGrid extends StatelessWidget {
  const _AllCategoriesGrid({required this.categories});

  final List<CategoryData> categories;

  @override
  Widget build(BuildContext context) {
    return SliverGridLayout(
      itemCount: categories.length,
      mainAxisExtent: CategoryTile.heightFor(context),
      mainAxisSpacing: AppCategoryLayout.rowSpacing,
      minimumCardWidth: AppCategoryLayout.cardWidth,
      minCrossAxisCount: AppCategoryLayout.columns,
      maxCrossAxisCount: AppCategoryLayout.columns,
      itemBuilder: (context, index) {
        final category = categories[index];
        final countLabel = category.marketCount == null
            ? category.productCountLabel
            : category.marketCountLabel;
        return CategoryTile(
          key: ValueKey('all_category_${category.id}'),
          name: category.name,
          image: category.image,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.brandProducts,
              arguments: BrandProductsRouteArgs(
                brand: category.name,
                productCount: countLabel,
                logo: category.image,
                classificationId: category.id,
              ),
            );
          },
        );
      },
    );
  }
}
