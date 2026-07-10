import 'package:flutter/material.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/constants/app_colors.dart';
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

    return SizedBox(
      height: 82,
      child: ListView.builder(
        itemExtent: 94,
        itemCount: visibleCategories.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final category = visibleCategories[index];
          return GestureDetector(
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
        },
      ),
    );
  }

  List<_HomeCategoryViewData> _visibleCategories() {
    final apiCategories = categories;
    if (apiCategories != null && apiCategories.isNotEmpty) {
      return apiCategories
          .take(8)
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
      width: 86,
      margin: const EdgeInsetsDirectional.only(end: 8),
      padding: const EdgeInsets.all(7),
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
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RepaintBoundary(
              child: AppImage(
                source: data.image,
                fallbackType: AppImagePlaceholderType.category,
                fit: BoxFit.contain,
                cacheWidth: 72,
                cacheHeight: 72,
                filterQuality: FilterQuality.low,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(data.name),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontSize: 12,
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
