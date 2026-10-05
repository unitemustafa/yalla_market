import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/presentation/widgets/brands/category_tile.dart';
import '../../../../app/routing/app_route_arguments.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../store/domain/entities/category_data.dart';

class HomeCategories extends StatelessWidget {
  const HomeCategories({super.key, this.categories});

  final List<CategoryData>? categories;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _visibleCategories();
    if (visibleCategories.isEmpty) return const SizedBox.shrink();

    Widget buildCategory(_HomeCategoryViewData category) {
      return CategoryTile(
        key: ValueKey('home_category_${category.id}'),
        name: category.name,
        image: category.image,
        accentColor: category.color,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.brandProducts,
            arguments: BrandProductsRouteArgs(
              brand: category.name,
              logo: category.image,
              productCount: category.productCountLabel,
              classificationId: category.id,
            ),
          );
        },
      );
    }

    return SizedBox(
      height: AppCategoryLayout.height,
      child: Row(
        key: const ValueKey('popular_categories_list'),
        children: [
          for (var index = 0; index < AppCategoryLayout.columns; index++) ...[
            if (index > 0) const SizedBox(width: AppCategoryLayout.spacing),
            Expanded(
              child: index < visibleCategories.length
                  ? buildCategory(visibleCategories[index])
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  List<_HomeCategoryViewData> _visibleCategories() {
    final apiCategories = categories;
    if (apiCategories != null && apiCategories.isNotEmpty) {
      return apiCategories
          .take(4)
          .map(
            (category) => _HomeCategoryViewData(
              id: category.id,
              name: category.name,
              image: category.image,
              productCountLabel: category.productCountLabel,
              color: Color(category.accentColorValue),
            ),
          )
          .toList(growable: false);
    }

    return const [];
  }
}

class _HomeCategoryViewData {
  const _HomeCategoryViewData({
    required this.id,
    required this.name,
    required this.image,
    required this.productCountLabel,
    required this.color,
  });

  final String id;
  final String name;
  final String image;
  final String productCountLabel;
  final Color color;
}
