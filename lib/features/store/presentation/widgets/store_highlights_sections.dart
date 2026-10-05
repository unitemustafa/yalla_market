import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/texts/section_heading.dart';
import '../../../../core/presentation/widgets/layouts/horizontal_card_layout.dart';
import '../../../../app/routing/app_route_arguments.dart';
import '../../../../app/routing/app_routes.dart';
import '../../domain/entities/store_data.dart';
import 'store_market_card.dart';

/// The store discovery rows shown on the home page.
class StoreHighlightsSections extends StatelessWidget {
  const StoreHighlightsSections({super.key, required this.store});

  final StoreData store;

  @override
  Widget build(BuildContext context) {
    final popularMarkets = store.popularMarkets;
    final hasPopularStores = popularMarkets.isNotEmpty;
    final hasLatestStores = store.latestMarkets.isNotEmpty;
    if (!hasPopularStores && !hasLatestStores) return const SizedBox.shrink();

    return Column(
      key: const ValueKey('home_store_highlights'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPopularStores)
          _StoresSection(
            title: 'Popular Stores',
            markets: popularMarkets,
            prefix: 'popular',
            previewLimit: 5,
            viewAllRoute: AppRoutes.popularStores,
          ),
        if (hasPopularStores && hasLatestStores) const SizedBox(height: 22),
        if (hasLatestStores)
          _StoresSection(
            title: 'Latest Stores',
            markets: store.latestMarkets,
            prefix: 'latest',
            previewLimit: 6,
            viewAllRoute: AppRoutes.latestStores,
          ),
      ],
    );
  }
}

class _StoresSection extends StatelessWidget {
  const _StoresSection({
    required this.title,
    required this.markets,
    required this.prefix,
    required this.previewLimit,
    required this.viewAllRoute,
  });

  final String title;
  final List<StoreMarketData> markets;
  final String prefix;
  final int previewLimit;
  final String viewAllRoute;

  void _openStore(BuildContext context, StoreMarketData market) {
    Navigator.pushNamed(
      context,
      AppRoutes.brandProducts,
      arguments: BrandProductsRouteArgs(
        brand: market.name,
        logo: market.image,
        productCount: market.productCountLabel,
        classificationId: market.classificationId,
        marketId: market.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleMarkets = markets.take(previewLimit).toList(growable: false);
    final showViewAll = markets.length > visibleMarkets.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          title: title,
          titleFontSize: 17,
          showActionButton: false,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: StoreMarketCard.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = compactHorizontalCardWidth(
                constraints.maxWidth,
              );
              return ListView.separated(
                key: ValueKey('${prefix}_stores_horizontal_slider'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: visibleMarkets.length + (showViewAll ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (showViewAll && index == visibleMarkets.length) {
                    return _StoresViewAllCard(
                      prefix: prefix,
                      route: viewAllRoute,
                    );
                  }
                  final market = visibleMarkets[index];
                  return SizedBox(
                    key: ValueKey('${prefix}_store_${market.id}'),
                    width: cardWidth,
                    child: StoreMarketCard(
                      market: market,
                      keyPrefix: '${prefix}_store',
                      onTap: () => _openStore(context, market),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoresViewAllCard extends StatelessWidget {
  const _StoresViewAllCard({required this.prefix, required this.route});

  final String prefix;
  final String route;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SizedBox(
      key: ValueKey('${prefix}_stores_view_all'),
      width: 84,
      child: Material(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('View all'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w800,
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
