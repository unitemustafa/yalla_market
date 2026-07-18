import 'package:flutter/material.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../store/data/demo/demo_categories.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../store/domain/entities/category_data.dart';

class HomeCategories extends StatelessWidget {
  const HomeCategories({super.key, this.categories});

  final List<CategoryData>? categories;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _visibleCategories();
    if (visibleCategories.isEmpty) return const SizedBox.shrink();

    Widget buildCategory(_HomeCategoryViewData category) {
      return GestureDetector(
        key: ValueKey('home_category_${category.id}'),
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
        child: _HomeCategoryChip(data: category),
      );
    }

    return SizedBox(
      height: 78,
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

    if (!AppEnvironment.useDemoRepositories) return const [];

    const fallbackCategories = [
      MarketCategories.restaurants,
      MarketCategories.supermarket,
      MarketCategories.vegetables,
      MarketCategories.fruits,
    ];
    return fallbackCategories
        .map(
          (category) => _HomeCategoryViewData(
            id: _slugFrom(category.name),
            name: category.name,
            image: category.image,
            productCountLabel: category.count,
            color: category.color,
          ),
        )
        .toList(growable: false);
  }
}

class _HomeCategoryChip extends StatelessWidget {
  const _HomeCategoryChip({required this.data});

  final _HomeCategoryViewData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 42,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RepaintBoundary(
              child: AppImage(
                source: data.image,
                fallbackType: AppImagePlaceholderType.category,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(6),
                cacheWidth: 128,
                cacheHeight: 128,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(data.name),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontSize: AppFontSizes.caption,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

String _slugFrom(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
