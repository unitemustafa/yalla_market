import 'package:flutter/material.dart';

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
      height: 106,
      child: Row(
        key: const ValueKey('popular_categories_list'),
        children: visibleCategories.length > 1
            ? List.generate(visibleCategories.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: index == visibleCategories.length - 1 ? 0 : 6,
                    ),
                    child: buildCategory(visibleCategories[index]),
                  ),
                );
              })
            : List.generate(visibleCategories.length, (index) {
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: index == visibleCategories.length - 1 ? 0 : 6,
                  ),
                  child: SizedBox(
                    width: 74,
                    child: buildCategory(visibleCategories[index]),
                  ),
                );
              }),
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
