import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../wishlist/presentation/cubit/market_wishlist_cubit.dart';
import '../../../wishlist/presentation/widgets/market_favorite_action.dart';
import '../../domain/entities/store_data.dart';

/// The shared store row used everywhere a market is listed.
///
/// Its proportions intentionally mirror a compact delivery-app store row:
/// square cover at the leading edge, logo over the cover and the useful
/// delivery information beside it. App colors, typography and icons remain
/// the Yalla Market design language.
class StoreMarketCard extends StatelessWidget {
  const StoreMarketCard({
    super.key,
    required this.market,
    required this.onTap,
    this.keyPrefix = 'store',
  });

  static const double height = 126;

  final StoreMarketData market;
  final VoidCallback onTap;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkCardColor : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.055);

    return SizedBox(
      height: height,
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 112,
                  child: _StoreCover(market: market, keyPrefix: keyPrefix),
                ),
                const SizedBox(width: 12),
                Expanded(child: _StoreInformation(market: market)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreCover extends StatelessWidget {
  const _StoreCover({required this.market, required this.keyPrefix});

  final StoreMarketData market;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    MarketWishlistCubit? wishlist;
    try {
      wishlist = context.read<MarketWishlistCubit>();
    } on Object {
      wishlist = null;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppImage(
            key: ValueKey('${keyPrefix}_${market.id}_cover'),
            source: market.coverImage,
            fallbackType: AppImagePlaceholderType.store,
            fit: BoxFit.cover,
            cacheWidth: 340,
            cacheHeight: 340,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.02),
                  Colors.black.withValues(alpha: 0.20),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 6,
            start: 6,
            child: wishlist == null
                ? _FavoriteButton(favorite: market.isLiked, isDark: isDark)
                : BlocBuilder<MarketWishlistCubit, MarketWishlistState>(
                    bloc: wishlist,
                    buildWhen: (previous, current) =>
                        previous.items != current.items ||
                        previous.busyIds != current.busyIds,
                    builder: (context, state) {
                      final cubit = wishlist!;
                      return _FavoriteButton(
                        key: ValueKey('${keyPrefix}_${market.id}_favorite'),
                        favorite: cubit.isFavorite(market),
                        isDark: isDark,
                        onPressed: state.busyIds.contains(market.id)
                            ? null
                            : () => toggleMarketFavoriteWithFeedback(
                                context: context,
                                cubit: cubit,
                                market: market,
                              ),
                      );
                    },
                  ),
          ),
          PositionedDirectional(
            end: 6,
            bottom: 6,
            child: Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardColor : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AppImage(
                key: ValueKey('${keyPrefix}_${market.id}_logo'),
                source: market.image,
                fallbackType: AppImagePlaceholderType.store,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(11),
                cacheWidth: 170,
                cacheHeight: 170,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    super.key,
    required this.favorite,
    required this.isDark,
    this.onPressed,
  });

  final bool favorite;
  final bool isDark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? Colors.black.withValues(alpha: 0.62)
          : Colors.white.withValues(alpha: 0.93),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            favorite ? AppIcons.heart5 : AppIcons.heart,
            color: favorite
                ? AppColors.error
                : (isDark ? Colors.white : AppColors.lightTextPrimary),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _StoreInformation extends StatelessWidget {
  const _StoreInformation({required this.market});

  final StoreMarketData market;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final count = market.effectiveProductCount;
    final delivery = _deliveryLabel(arabic);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 9, 0, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            market.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (market.description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              market.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: muted,
                fontSize: 10.5,
                height: 1.3,
              ),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _Meta(
                  icon: AppIcons.box,
                  text:
                      '$count ${arabic
                          ? 'منتج'
                          : count == 1
                          ? 'product'
                          : 'products'}',
                  color: muted,
                ),
              ),
              if (delivery != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '•',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: _Meta(
                    icon: AppIcons.truck_fast,
                    text: delivery,
                    color: muted,
                  ),
                ),
              ],
            ],
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

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
