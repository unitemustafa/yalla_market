import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/presentation/media/media_focal_point_alignment.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../wishlist/presentation/cubit/market_wishlist_cubit.dart';
import '../../../wishlist/presentation/widgets/market_favorite_action.dart';
import '../../domain/entities/store_data.dart';

/// Shared store card with details floating over the lower part of its cover.
class StoreMarketCard extends StatelessWidget {
  const StoreMarketCard({
    super.key,
    required this.market,
    required this.onTap,
    this.keyPrefix = 'store',
  });

  static const double height = 196;

  final StoreMarketData market;
  final VoidCallback onTap;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                height: 132,
                child: _StoreCover(market: market, keyPrefix: keyPrefix),
              ),
              PositionedDirectional(
                top: 84,
                bottom: 8,
                start: 8,
                end: 8,
                child: _StoreDetails(market: market, keyPrefix: keyPrefix),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreDetails extends StatelessWidget {
  const _StoreDetails({required this.market, required this.keyPrefix});

  final StoreMarketData market;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.055);
    final count = market.effectiveProductCount;
    final delivery = _deliveryLabel(arabic);

    return Container(
      key: ValueKey('${keyPrefix}_${market.id}_details'),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _StoreLogo(market: market, keyPrefix: keyPrefix),
                  const SizedBox(width: 7),
                  Expanded(child: _StoreInformation(market: market)),
                ],
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: border),
          SizedBox(
            height: 36,
            child: Row(
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
                  Container(width: 1, height: 22, color: border),
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
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppImage(
            key: ValueKey('${keyPrefix}_${market.id}_cover'),
            source: market.coverImage,
            fallbackType: AppImagePlaceholderType.store,
            fit: BoxFit.cover,
            alignment: market.coverFocus.alignment,
            cacheWidth: 1080,
            cacheHeight: 528,
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
            top: 10,
            start: 10,
            child: wishlist == null
                ? _FavoriteButton(
                    key: ValueKey('${keyPrefix}_${market.id}_favorite'),
                    favorite: market.isLiked,
                    isDark: isDark,
                  )
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
        ],
      ),
    );
  }
}

class _StoreLogo extends StatelessWidget {
  const _StoreLogo({required this.market, required this.keyPrefix});

  final StoreMarketData market;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: AppImage(
        key: ValueKey('${keyPrefix}_${market.id}_logo'),
        source: market.image,
        fallbackType: AppImagePlaceholderType.store,
        role: AppImageRole.logo,
        borderRadius: BorderRadius.circular(5),
        cacheWidth: 228,
        cacheHeight: 228,
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
          width: 40,
          height: 40,
          child: Icon(
            favorite ? AppIcons.heart5 : AppIcons.heart,
            color: favorite
                ? AppColors.error
                : (isDark ? Colors.white : AppColors.lightTextPrimary),
            size: 21,
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
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
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
            ),
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: AppColors.primary, size: 13),
          ],
        ),
        if (market.description.isNotEmpty) ...[
          const SizedBox(height: 4),
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
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10.5,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
