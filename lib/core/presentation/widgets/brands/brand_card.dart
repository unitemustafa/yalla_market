import 'package:flutter/material.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../../localization/app_translations.dart';
import '../images/app_image.dart';

class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.showBorder,
    this.onTap,
    this.brand = 'مطاعم',
    this.productCount = '265 products',
    this.logo = AppAssets.temporaryMarketPlaceholder,
    this.accentColor = AppColors.primary,
  });

  final bool showBorder;
  final void Function()? onTap;
  final String brand;
  final String productCount;
  final String logo;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final logoBackground = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : accentColor.withValues(alpha: 0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: showBorder ? panelColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: showBorder ? Border.all(color: borderColor) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: logoBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppImage(
                  source: logo,
                  fallbackType: AppImagePlaceholderType.store,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(6),
                  cacheWidth: 112,
                  cacheHeight: 112,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          AppIcons.verify5,
                          color: AppColors.primary,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            brand,
                            textAlign: TextAlign.start,
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                            softWrap: true,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(productCount),
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium!.apply(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
