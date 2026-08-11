import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../offers/domain/entities/offer_data.dart';
import '../../../../offers/presentation/widgets/promo_slider.dart';
import '../../../domain/entities/product_data.dart';

class StoreOfferSection extends StatelessWidget {
  const StoreOfferSection({super.key, required this.offers});

  final List<OfferData> offers;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('store_offer_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Offers'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        PromoSlider(offers: offers),
      ],
    );
  }
}

class StoreSubcategoryRail extends StatelessWidget {
  const StoreSubcategoryRail({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.languageCode,
    required this.categoryDescription,
    required this.onSelected,
  });

  final List<StoreSubcategoryData> categories;
  final String? selectedId;
  final String languageCode;
  final String? categoryDescription;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: SizedBox(
            height: 47,
            child: ListView.separated(
              key: const ValueKey('store_subcategory_rail'),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final category = index == 0 ? null : categories[index - 1];
                final isSelected = category?.id == selectedId;
                final label = category == null
                    ? (languageCode.startsWith('ar') ? 'الكل' : 'All')
                    : category.localizedName(languageCode);
                return InkWell(
                  key: ValueKey(
                    category == null
                        ? 'store_subcategory_all'
                        : 'store_subcategory_${category.id}',
                  ),
                  onTap: () => onSelected(category?.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (category == null) ...[
                          Icon(
                            AppIcons.category,
                            size: 16,
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.1,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (categoryDescription?.isNotEmpty == true) ...[
          const SizedBox(height: 7),
          Text(
            categoryDescription!,
            key: const ValueKey('store_subcategory_description'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11.5,
            ),
          ),
        ],
      ],
    );
  }
}

class LocalCategoryHeader extends StatelessWidget {
  const LocalCategoryHeader({
    super.key,
    required this.title,
    required this.logo,
    required this.cityName,
    required this.shopCount,
  });

  final String title;
  final String logo;
  final String cityName;
  final int shopCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppImage(
              source: logo,
              fallbackType: AppImagePlaceholderType.store,
              fit: BoxFit.contain,
              cacheWidth: 108,
              cacheHeight: 108,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  shopCount == 0
                      ? 'لا يوجد محلات متاحة في $cityName'
                      : '$shopCount محل متاح في $cityName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
