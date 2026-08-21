import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/texts/section_heading.dart';
import '../../../../app/routing/app_route_arguments.dart';
import '../../../../app/routing/app_routes.dart';
import '../../domain/entities/store_data.dart';
import 'store_market_card.dart';

/// The store discovery rows shown on the home page.
class StoreHighlightsSections extends StatefulWidget {
  const StoreHighlightsSections({super.key, required this.store});

  final StoreData store;

  @override
  State<StoreHighlightsSections> createState() =>
      _StoreHighlightsSectionsState();
}

class _StoreHighlightsSectionsState extends State<StoreHighlightsSections> {
  String? _selectedClassificationId;

  @override
  Widget build(BuildContext context) {
    final popularClassifications = widget.store.classifications
        .where(
          (classification) =>
              widget.store.popularMarketsFor(classification.id).isNotEmpty,
        )
        .toList(growable: false);
    final selectedClassification = _selectedClassification(
      popularClassifications,
    );
    final selectedMarkets = selectedClassification == null
        ? const <StoreMarketData>[]
        : widget.store.popularMarketsFor(selectedClassification.id);
    final hasPopularStores = selectedClassification != null;
    final hasLatestStores = widget.store.latestMarkets.isNotEmpty;

    if (!hasPopularStores && !hasLatestStores) return const SizedBox.shrink();

    return Column(
      key: const ValueKey('home_store_highlights'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPopularStores)
          _PopularStoresSection(
            classifications: popularClassifications,
            marketCounts: {
              for (final classification in popularClassifications)
                classification.id: widget.store
                    .popularMarketsFor(classification.id)
                    .length,
            },
            selectedClassification: selectedClassification,
            markets: selectedMarkets,
            onClassificationSelected: (classification) {
              if (classification.id == selectedClassification.id) return;
              setState(() => _selectedClassificationId = classification.id);
            },
          ),
        if (hasPopularStores && hasLatestStores) const SizedBox(height: 22),
        if (hasLatestStores)
          _LatestStoresSection(markets: widget.store.latestMarkets),
      ],
    );
  }

  StoreClassificationData? _selectedClassification(
    List<StoreClassificationData> classifications,
  ) {
    if (classifications.isEmpty) return null;
    for (final classification in classifications) {
      if (classification.id == _selectedClassificationId) {
        return classification;
      }
    }
    return classifications.first;
  }
}

class _LatestStoresSection extends StatelessWidget {
  const _LatestStoresSection({required this.markets});

  final List<StoreMarketData> markets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          title: 'Latest Stores',
          titleFontSize: 17,
          showActionButton: false,
        ),
        const SizedBox(height: 12),
        _LatestStoresSlider(markets: markets),
      ],
    );
  }
}

class _LatestStoresSlider extends StatelessWidget {
  const _LatestStoresSlider({required this.markets});

  final List<StoreMarketData> markets;

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
    final visibleMarkets = markets.take(6).toList(growable: false);
    final showViewAll = markets.length > visibleMarkets.length;

    return SizedBox(
      height: StoreMarketCard.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth * 0.92)
              .clamp(280.0, 360.0)
              .toDouble();

          return ListView.separated(
            key: const ValueKey('latest_stores_horizontal_slider'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: visibleMarkets.length + (showViewAll ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (showViewAll && index == visibleMarkets.length) {
                return const _LatestStoresViewAllCard();
              }

              final market = visibleMarkets[index];
              return SizedBox(
                key: ValueKey('latest_store_${market.id}'),
                width: cardWidth,
                child: StoreMarketCard(
                  market: market,
                  keyPrefix: 'latest_store',
                  onTap: () => _openStore(context, market),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LatestStoresViewAllCard extends StatelessWidget {
  const _LatestStoresViewAllCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SizedBox(
      key: const ValueKey('latest_stores_view_all'),
      width: 84,
      child: Material(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.latestStores),
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

class _PopularStoresSection extends StatelessWidget {
  const _PopularStoresSection({
    required this.classifications,
    required this.marketCounts,
    required this.selectedClassification,
    required this.markets,
    required this.onClassificationSelected,
  });

  final List<StoreClassificationData> classifications;
  final Map<String, int> marketCounts;
  final StoreClassificationData selectedClassification;
  final List<StoreMarketData> markets;
  final ValueChanged<StoreClassificationData> onClassificationSelected;

  void _openStore(BuildContext context, StoreMarketData market) {
    Navigator.pushNamed(
      context,
      AppRoutes.brandProducts,
      arguments: BrandProductsRouteArgs(
        brand: market.name,
        logo: market.image,
        productCount: market.productCountLabel,
        classificationId: selectedClassification.id,
        marketId: market.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          title: 'Popular Stores',
          titleFontSize: 17,
          showActionButton: false,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            key: const ValueKey('popular_store_category_selector'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: classifications.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final classification = classifications[index];
              return _PopularCategoryChip(
                key: ValueKey('popular_store_category_${classification.id}'),
                label: context.tr(classification.name),
                count: marketCounts[classification.id] ?? 0,
                selected: classification.id == selectedClassification.id,
                onTap: () => onClassificationSelected(classification),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth * 0.92)
                .clamp(280.0, 360.0)
                .toDouble();
            return SizedBox(
              height: StoreMarketCard.height,
              child: ListView.separated(
                key: const ValueKey('popular_stores_horizontal_slider'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: markets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final market = markets[index];
                  return SizedBox(
                    key: ValueKey('popular_store_${market.id}'),
                    width: cardWidth,
                    child: StoreMarketCard(
                      market: market,
                      keyPrefix: 'popular_store',
                      onTap: () => _openStore(context, market),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PopularCategoryChip extends StatelessWidget {
  const _PopularCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = selected
        ? AppColors.primary
        : (isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.07));
    final foregroundColor = selected
        ? Colors.white
        : (isDark ? Colors.white : AppColors.lightTextPrimary);

    return Material(
      color: selected
          ? AppColors.primary
          : (isDark ? AppColors.darkCardColor : Colors.white),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 7),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w900,
                    ),
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
