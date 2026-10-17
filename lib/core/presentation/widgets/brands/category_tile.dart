import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/app_translations.dart';
import '../images/app_image.dart';
import 'category_label.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.name,
    required this.image,
    required this.onTap,
  });

  final String name;
  final String image;
  final VoidCallback onTap;

  static double heightFor(BuildContext context) =>
      AppCategoryLayout.height +
      CategoryLabel.heightFor(context, AppFontSizes.caption) -
      (AppFontSizes.caption * CategoryLabel.lineHeight * 2 + 4);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? AppColors.darkCardColor
        : AppColors.categoryCardBackground;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    return Material(
      color: panelColor,
      borderRadius: BorderRadius.circular(AppCategoryLayout.cornerRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppCategoryLayout.cornerRadius),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: AppCategoryLayout.iconSize,
                child: Center(
                  child: RepaintBoundary(
                    child: AppImage(
                      source: image,
                      width: AppCategoryLayout.iconSize,
                      height: AppCategoryLayout.iconSize,
                      fallbackType: AppImagePlaceholderType.category,
                      role: AppImageRole.illustration,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: CategoryLabel(
                    label: context.tr(name),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: textColor,
                      fontSize: AppFontSizes.caption,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
