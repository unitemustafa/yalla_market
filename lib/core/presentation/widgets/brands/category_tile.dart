import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/app_translations.dart';
import '../images/app_image.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.name,
    required this.image,
    required this.accentColor,
    required this.onTap,
    this.countLabel,
    this.compact = false,
  });

  final String name;
  final String image;
  final Color accentColor;
  final VoidCallback onTap;
  final String? countLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final normalizedCount = countLabel?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: EdgeInsets.all(compact ? 4 : 5),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: compact ? 72 : 90,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.18 : 0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RepaintBoundary(
                    child: AppImage(
                      source: image,
                      fallbackType: AppImagePlaceholderType.category,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      cacheWidth: compact ? 192 : 256,
                      cacheHeight: compact ? 216 : 256,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 4 : 5),
              Text(
                context.tr(name),
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontSize: compact ? AppFontSizes.caption : AppFontSizes.small,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!compact && normalizedCount.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  context.tr(normalizedCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: mutedColor,
                    fontSize: AppFontSizes.caption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
