import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../domain/entities/store_data.dart';

class StoreMarketCard extends StatelessWidget {
  const StoreMarketCard({
    super.key,
    required this.market,
    required this.onTap,
    this.keyPrefix = 'store',
  });

  static const double height = 184;

  final StoreMarketData market;
  final VoidCallback onTap;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Color(market.accentColorValue);
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final actualImages = market.products
        .map((product) => product.image.trim())
        .where((image) => image.isNotEmpty)
        .take(3)
        .toList(growable: false);
    final defaultImage = isDark
        ? AppAssets.emptyStoreDark
        : AppAssets.emptyStoreLight;
    final imageSlots = List.generate(
      3,
      (index) => index < actualImages.length
          ? _StoreImageSlotData(source: actualImages[index], isDefault: false)
          : _StoreImageSlotData(source: defaultImage, isDefault: true),
      growable: false,
    );
    final forwardIcon = Directionality.of(context) == TextDirection.rtl
        ? AppIcons.arrow_left_2
        : AppIcons.arrow_right_3;

    return SizedBox(
      height: height,
      child: Material(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: isDark ? 0.18 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: AppImage(
                        source: market.image,
                        fallbackType: AppImagePlaceholderType.store,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(9),
                        cacheWidth: 76,
                        cacheHeight: 76,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  market.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                AppIcons.verify5,
                                color: AppColors.primary,
                                size: 13,
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            context.tr(market.productCountLabel),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: isDark ? 0.18 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        forwardIcon,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: _StoreImageSlot(
                          marketId: market.id,
                          index: 0,
                          data: imageSlots[0],
                          keyPrefix: keyPrefix,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Expanded(
                              child: _StoreImageSlot(
                                marketId: market.id,
                                index: 1,
                                data: imageSlots[1],
                                keyPrefix: keyPrefix,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Expanded(
                              child: _StoreImageSlot(
                                marketId: market.id,
                                index: 2,
                                data: imageSlots[2],
                                keyPrefix: keyPrefix,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreImageSlot extends StatelessWidget {
  const _StoreImageSlot({
    required this.marketId,
    required this.index,
    required this.data,
    required this.keyPrefix,
  });

  final String marketId;
  final int index;
  final _StoreImageSlotData data;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return AppImage(
      key: ValueKey(
        '${keyPrefix}_${marketId}_${data.isDefault ? 'default' : 'product'}_$index',
      ),
      source: data.source,
      fallbackType: data.isDefault ? null : AppImagePlaceholderType.product,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
      cacheWidth: 320,
      cacheHeight: 260,
    );
  }
}

class _StoreImageSlotData {
  const _StoreImageSlotData({required this.source, required this.isDefault});

  final String source;
  final bool isDefault;
}
