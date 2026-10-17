import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/texts/section_heading.dart';
import '../../../../core/presentation/widgets/layouts/centered_card_carousel.dart';
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
          showActionButton: showViewAll,
          onPressed: showViewAll
              ? () => Navigator.pushNamed(context, viewAllRoute)
              : null,
        ),
        const SizedBox(height: 12),
        CenteredCardCarousel(
          key: ValueKey((
            prefix,
            Object.hashAll(visibleMarkets.map((m) => m.id)),
          )),
          sliderKey: ValueKey('${prefix}_stores_horizontal_slider'),
          itemHeight: StoreMarketCard.heightFor(context),
          itemCount: visibleMarkets.length,
          itemBuilder: (context, index) {
            final market = visibleMarkets[index];
            return StoreMarketCard(
              key: ValueKey('${prefix}_store_${market.id}'),
              market: market,
              keyPrefix: '${prefix}_store',
              onTap: () => _openStore(context, market),
            );
          },
        ),
      ],
    );
  }
}
