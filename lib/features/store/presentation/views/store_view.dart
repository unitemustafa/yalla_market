import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/address_required_error.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/brands/brand_card.dart';
import '../../../../core/presentation/widgets/brands/brand_showcase.dart';
import '../../../../core/presentation/widgets/layouts/grid_layout.dart';
import '../../../../core/presentation/widgets/products/cart_counter_icon.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../core/presentation/widgets/texts/section_heading.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/store_data.dart';
import '../cubit/store_cubit.dart';
import '../cubit/store_state.dart';

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
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

        final featured = store!.commonClassifications.isEmpty
            ? classifications.take(4).toList(growable: false)
            : store.commonClassifications;

        return DefaultTabController(
          key: ValueKey(classifications.map((item) => item.id).join('|')),
          length: classifications.length,
          child: Scaffold(
            backgroundColor: backgroundColor,
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<StoreCubit>().loadStore(force: true),
                child: NestedScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  headerSliverBuilder: (_, _) {
                    return [
                      SliverToBoxAdapter(
                        child: ColoredBox(
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
                                SectionHeading(
                                  title: context.tr('Featured Categories'),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.categories,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                GridLayout(
                                  itemCount: featured.length,
                                  mainAxisExtent: 78,
                                  itemBuilder: (_, index) {
                                    final category = featured[index];
                                    return BrandCard(
                                      showBorder: true,
                                      brand: category.name,
                                      productCount: category.productCountLabel,
                                      logo: category.image,
                                      accentColor: Color(
                                        category.accentColorValue,
                                      ),
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.brandProducts,
                                          arguments: BrandProductsRouteArgs(
                                            brand: category.name,
                                            logo: category.image,
                                            productCount:
                                                category.productCountLabel,
                                            classificationId: category.id,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StoreTabsHeaderDelegate(
                          backgroundColor: backgroundColor,
                          isDark: isDark,
                          labels: classifications
                              .map((category) => category.name)
                              .toList(growable: false),
                        ),
                      ),
                    ];
                  },
                  body: ColoredBox(
                    color: backgroundColor,
                    child: TabBarView(
                      children: classifications
                          .map(
                            (classification) => _StoreMarketsTab(
                              classification: classification,
                              markets: store.marketsFor(classification.id),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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

class _StoreMarketsTab extends StatelessWidget {
  const _StoreMarketsTab({required this.classification, required this.markets});

  final StoreClassificationData classification;
  final List<StoreMarketData> markets;

  @override
  Widget build(BuildContext context) {
    if (markets.isEmpty) {
      return AppEmptyState(
        title: context.tr('No stores available'),
        message: context.tr(
          'Stores will appear here when they cover your address.',
        ),
        icon: AppIcons.shop,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: markets.length,
      itemBuilder: (_, index) {
        final market = markets[index];
        return BrandShowcase(
          brand: market.name,
          productCount: market.productCountLabel,
          logo: market.image,
          accentColor: Color(market.accentColorValue),
          images: market.products
              .map((product) => product.image)
              .take(3)
              .toList(growable: false),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.brandProducts,
              arguments: BrandProductsRouteArgs(
                brand: market.name,
                logo: market.image,
                productCount: market.productCountLabel,
                classificationId: classification.id,
                marketId: market.id,
              ),
            );
          },
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

class _StoreTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StoreTabsHeaderDelegate({
    required this.backgroundColor,
    required this.isDark,
    required this.labels,
  });

  final Color backgroundColor;
  final bool isDark;
  final List<String> labels;

  @override
  double get minExtent => 62;

  @override
  double get maxExtent => 62;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final tabTextStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800);

    return Material(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.all(4),
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            unselectedLabelColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            labelColor: Colors.white,
            labelStyle: tabTextStyle,
            unselectedLabelStyle: tabTextStyle,
            tabs: labels
                .map((label) => Tab(height: 34, child: Text(context.tr(label))))
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StoreTabsHeaderDelegate oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.labels.length != labels.length;
  }
}
