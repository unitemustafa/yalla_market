import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/formatters/app_currency.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../wishlist/presentation/cubit/market_wishlist_cubit.dart';
import '../../../wishlist/presentation/widgets/market_favorite_action.dart';
import '../../domain/entities/store_data.dart';

class MarketStorefrontHero extends StatelessWidget {
  const MarketStorefrontHero({
    super.key,
    required this.market,
    required this.onBack,
    required this.onSearch,
    required this.onShare,
  });

  final StoreMarketData market;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final surface = isDark ? AppColors.darkCardColor : Colors.white;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final delivery = _deliveryLabel(arabic);
    final minimumPrice = market.minimumProductPrice;

    return SizedBox(
      key: const ValueKey('storefront_hero'),
      height: safeTop + 318,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            height: safeTop + 214,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  key: const ValueKey('storefront_cover'),
                  source: market.coverImage,
                  fallbackType: AppImagePlaceholderType.store,
                  fit: BoxFit.cover,
                  cacheWidth: 1080,
                  cacheHeight: 720,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.17),
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            top: safeTop + 10,
            start: 16,
            end: 16,
            child: Row(
              children: [
                _HeroCircleButton(
                  key: const ValueKey('storefront_back_button'),
                  icon: Directionality.of(context) == TextDirection.rtl
                      ? AppIcons.arrow_right_3
                      : AppIcons.arrow_left_2,
                  onTap: onBack,
                ),
                const Spacer(),
                _HeroCircleButton(
                  key: const ValueKey('storefront_search_button'),
                  icon: AppIcons.search_normal,
                  onTap: onSearch,
                ),
                const SizedBox(width: 8),
                _HeroCircleButton(
                  key: const ValueKey('storefront_share_button'),
                  icon: AppIcons.send_1,
                  onTap: onShare,
                ),
                const SizedBox(width: 8),
                _FavoriteHeroButton(market: market),
              ],
            ),
          ),
          PositionedDirectional(
            top: safeTop + 146,
            start: 16,
            end: 16,
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.055),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.11),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: AppImage(
                            key: const ValueKey('storefront_logo'),
                            source: market.image,
                            fallbackType: AppImagePlaceholderType.store,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(12),
                            cacheWidth: 180,
                            cacheHeight: 180,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                market.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontSize: 16,
                                      height: 1.25,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              if (market.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  market.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: muted,
                                        fontSize: 11.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.055),
                  ),
                  SizedBox(
                    height: 58,
                    child: Row(
                      children: [
                        if (delivery != null)
                          Expanded(
                            child: _MarketHeroMeta(
                              icon: AppIcons.truck_fast,
                              label: delivery,
                            ),
                          ),
                        if (delivery != null) const _HeroMetaDivider(),
                        Expanded(
                          child: _MarketHeroMeta(
                            icon: AppIcons.box,
                            label:
                                '${market.effectiveProductCount} '
                                '${arabic ? 'منتج' : 'products'}',
                          ),
                        ),
                        if (minimumPrice != null) ...[
                          const _HeroMetaDivider(),
                          Expanded(
                            child: _MarketHeroMeta(
                              icon: AppIcons.money_3,
                              label:
                                  '${arabic ? 'يبدأ من' : 'Starts from'} '
                                  '${AppCurrency.format(minimumPrice)}',
                              emphasized: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _deliveryLabel(bool arabic) {
    final minimum = market.deliveryTimeMinMinutes;
    final maximum = market.deliveryTimeMaxMinutes;
    if (minimum == null) return null;
    final value = maximum == null || maximum == minimum
        ? '$minimum'
        : '$minimum-$maximum';
    return '$value ${arabic ? 'دقيقة' : 'min'}';
  }
}

class _FavoriteHeroButton extends StatelessWidget {
  const _FavoriteHeroButton({required this.market});

  final StoreMarketData market;

  @override
  Widget build(BuildContext context) {
    MarketWishlistCubit? wishlist;
    try {
      wishlist = context.read<MarketWishlistCubit>();
    } on Object {
      wishlist = null;
    }

    if (wishlist == null) {
      return _HeroCircleButton(
        key: const ValueKey('storefront_favorite_button'),
        icon: market.isLiked ? AppIcons.heart5 : AppIcons.heart,
        iconColor: market.isLiked ? AppColors.error : null,
      );
    }

    return BlocBuilder<MarketWishlistCubit, MarketWishlistState>(
      bloc: wishlist,
      buildWhen: (previous, current) =>
          previous.items != current.items ||
          previous.busyIds != current.busyIds,
      builder: (context, state) {
        final cubit = wishlist!;
        final favorite = cubit.isFavorite(market);
        return _HeroCircleButton(
          key: const ValueKey('storefront_favorite_button'),
          icon: favorite ? AppIcons.heart5 : AppIcons.heart,
          iconColor: favorite ? AppColors.error : null,
          onTap: state.busyIds.contains(market.id)
              ? null
              : () => toggleMarketFavoriteWithFeedback(
                  context: context,
                  cubit: cubit,
                  market: market,
                ),
        );
      },
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    super.key,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}

class _MarketHeroMeta extends StatelessWidget {
  const _MarketHeroMeta({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized
        ? AppColors.primary
        : Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10.5,
              height: 1.15,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaDivider extends StatelessWidget {
  const _HeroMetaDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
    );
  }
}
