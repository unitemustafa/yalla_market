import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/address_required_error.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/brands/brand_card.dart';
import '../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../core/presentation/widgets/products/cart_counter_icon.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../core/presentation/widgets/texts/section_heading.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/store_data.dart';
import '../cubit/store_cubit.dart';
import '../cubit/store_state.dart';
import '../widgets/store_market_card.dart';

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  String? _selectedPopularClassificationId;

  Future<void> _refreshStore() {
    return context.read<StoreCubit>().loadStore(force: true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StoreCubit>().loadStore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) {
        final store = state.data;
        final classifications = store?.classifications ?? const [];

        if (state is StoreLoading && store == null) {
          return _StorePlainScaffold(
            backgroundColor: backgroundColor,
            isDark: isDark,
            onRefresh: () => context.read<StoreCubit>().loadStore(force: true),
            child: AppLoadingState(message: context.tr('Loading store...')),
          );
        }

        if (state is StoreFailure && store == null) {
          final requiresAddress = state.message == addressRequiredMessage;
          return _StorePlainScaffold(
            backgroundColor: backgroundColor,
            isDark: isDark,
            onRefresh: () => context.read<StoreCubit>().loadStore(force: true),
            child: requiresAddress
                ? AppStateView(
                    icon: AppIcons.location_add,
                    title: context.tr('Address required'),
                    message: context.tr(addressRequiredMessage),
                    actionLabel: context.tr('Add Address'),
                    onAction: () async {
                      await Navigator.pushNamed(context, AppRoutes.addresses);
                      if (context.mounted) {
                        await context.read<StoreCubit>().loadStore(force: true);
                      }
                    },
                  )
                : AppErrorState(
                    title: context.tr('Store could not load'),
                    message: context.tr(state.message),
                    onRetry: () =>
                        context.read<StoreCubit>().loadStore(force: true),
                  ),
          );
        }

        if (classifications.isEmpty) {
          return _StorePlainScaffold(
            backgroundColor: backgroundColor,
            isDark: isDark,
            onRefresh: () => context.read<StoreCubit>().loadStore(force: true),
            child: AppEmptyState(
              title: context.tr('No store categories'),
              message: context.tr(
                'Categories will appear here once stores are available.',
              ),
              icon: AppIcons.shop,
            ),
          );
        }

        final readyStore = store!;
        final featuredSlots = readyStore.featuredSlots;
        final showAllFeatured = readyStore.hasFeaturedOverflow;
        final popularClassifications = classifications
            .where(
              (classification) =>
                  readyStore.popularMarketsFor(classification.id).isNotEmpty,
            )
            .toList(growable: false);
        final hasPopularMarkets = popularClassifications.isNotEmpty;
        StoreClassificationData? selectedPopularClassification;
        if (hasPopularMarkets) {
          selectedPopularClassification = popularClassifications.first;
          for (final classification in popularClassifications) {
            if (classification.id == _selectedPopularClassificationId) {
              selectedPopularClassification = classification;
              break;
            }
          }
        }
        final selectedPopularMarkets = selectedPopularClassification == null
            ? const <StoreMarketData>[]
            : readyStore.popularMarketsFor(selectedPopularClassification.id);

        Widget buildStoreHeader() {
          return ColoredBox(
            color: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StoreTopBar(isDark: isDark),
                  const SizedBox(height: 18),
                  _StoreSearchField(isDark: isDark),
                  const SizedBox(height: 22),
                  if (featuredSlots.isNotEmpty) ...[
                    SectionHeading(
                      title: 'Featured Categories',
                      titleFontSize: 17,
                      showActionButton: showAllFeatured,
                      onPressed: showAllFeatured
                          ? () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.categories,
                                arguments: CategoriesRouteArgs(
                                  categories: readyStore.featuredCandidates
                                      .map(
                                        (classification) =>
                                            classification.toCategoryData(),
                                      )
                                      .toList(growable: false),
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _FeaturedCategoriesGrid(categories: featuredSlots),
                  ],
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: AppRefreshIndicator(
              onRefresh: _refreshStore,
              child: CustomScrollView(
                key: ValueKey(
                  hasPopularMarkets
                      ? 'store_scroll'
                      : 'store_without_popular_scroll',
                ),
                physics: AppRefreshIndicator.scrollPhysics,
                slivers: [
                  SliverToBoxAdapter(child: buildStoreHeader()),
                  if (selectedPopularClassification != null)
                    SliverToBoxAdapter(
                      child: _PopularStoresSection(
                        classifications: popularClassifications,
                        marketCounts: {
                          for (final classification in popularClassifications)
                            classification.id: readyStore
                                .popularMarketsFor(classification.id)
                                .length,
                        },
                        selectedClassification: selectedPopularClassification,
                        markets: selectedPopularMarkets,
                        onClassificationSelected: (classification) {
                          if (classification.id ==
                              selectedPopularClassification!.id) {
                            return;
                          }
                          setState(() {
                            _selectedPopularClassificationId =
                                classification.id;
                          });
                        },
                      ),
                    ),
                  if (readyStore.latestMarkets.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _LatestStoresSection(
                        markets: readyStore.latestMarkets,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LatestStoresSection extends StatelessWidget {
  const _LatestStoresSection({required this.markets});

  final List<StoreMarketData> markets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
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
      ),
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
          final cardWidth = (constraints.maxWidth * 0.76)
              .clamp(226.0, 286.0)
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

class _StorePlainScaffold extends StatelessWidget {
  const _StorePlainScaffold({
    required this.backgroundColor,
    required this.isDark,
    required this.onRefresh,
    required this.child,
  });

  final Color backgroundColor;
  final bool isDark;
  final RefreshCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AppRefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: AppRefreshIndicator.scrollPhysics,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StoreTopBar(isDark: isDark),
                const SizedBox(height: 18),
                _StoreSearchField(isDark: isDark),
                const SizedBox(height: 24),
                child,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
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
              final cardWidth = (constraints.maxWidth * 0.76)
                  .clamp(226.0, 286.0)
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
      ),
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

class _FeaturedCategoriesGrid extends StatelessWidget {
  const _FeaturedCategoriesGrid({required this.categories});

  final List<StoreClassificationData> categories;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(categories.length, (index) {
            final category = categories[index];
            final isOddLast =
                categories.length.isOdd && index == categories.length - 1;
            return SizedBox(
              key: ValueKey('featured_category_${category.id}'),
              width: isOddLast ? constraints.maxWidth : halfWidth,
              height: 92,
              child: BrandCard(
                showBorder: true,
                brand: category.name,
                productCount: category.marketCountLabel,
                logo: category.image,
                accentColor: Color(category.accentColorValue),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.brandProducts,
                    arguments: BrandProductsRouteArgs(
                      brand: category.name,
                      logo: category.image,
                      productCount: category.marketCountLabel,
                      classificationId: category.id,
                    ),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }
}

class _StoreTopBar extends StatelessWidget {
  const _StoreTopBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Store'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('Categories & picks'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: CartCounterIcon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.cart);
            },
            iconColor: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _StoreSearchField extends StatelessWidget {
  const _StoreSearchField({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Material(
      color: panelColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.search);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(AppIcons.search_normal, color: mutedColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('Search categories, products...'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.18 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  AppIcons.filter_search,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
