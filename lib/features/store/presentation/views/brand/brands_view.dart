import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/brands/brand_card.dart';
import '../../../../../core/presentation/widgets/layouts/grid_layout.dart';
import '../../../../../core/presentation/widgets/texts/section_heading.dart';
import '../../../../../core/routing/app_route_arguments.dart';
import '../../../../../core/routing/app_routes.dart';
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
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            children: [
              const PageTopBar(
                title: 'Categories',
                subtitle: 'Explore market categories',
              ),
              const SizedBox(height: 18),
              const SectionHeading(
                title: 'All Categories',
                showActionButton: false,
              ),
              const SizedBox(height: 16),
              if (categories?.isNotEmpty == true)
                _AllCategoriesGrid(categories: categories!)
              else
                BlocBuilder<ProductDiscoveryCubit, ProductDiscoveryState>(
                  builder: (context, state) {
                    if (state is ProductDiscoveryLoading &&
                        state.categories.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return _AllCategoriesGrid(
                      categories: categoriesForAllCategories(
                        discoveryCategories: state.categories,
                      ),
                    );
                  },
                ),
            ],
          ),
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
    return GridLayout(
      itemCount: categories.length,
      mainAxisExtent: 92,
      itemBuilder: (context, index) {
        final category = categories[index];
        final countLabel = category.marketCount == null
            ? category.productCountLabel
            : category.marketCountLabel;
        return BrandCard(
          key: ValueKey('all_category_${category.id}'),
          showBorder: true,
          brand: category.name,
          productCount: countLabel,
          logo: category.image,
          accentColor: Color(category.accentColorValue),
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
