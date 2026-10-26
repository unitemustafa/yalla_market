import '../../../../core/presentation/widgets/states/app_skeleton.dart';
import 'dart:async';
import 'package:yalla_market/core/constants/app_constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../core/presentation/widgets/brands/brand_card.dart';
import '../../../../core/presentation/widgets/products/product_cards_sliver.dart';
import '../../../../core/presentation/widgets/products/product_results_view.dart'
    show productCardId, productCardTileData;
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../core/preferences/app_preferences_controller.dart';
import '../../../../app/routing/app_route_arguments.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../store/domain/entities/category_data.dart';
import '../../../store/domain/entities/product_data.dart';
import '../cubit/catalog_search_cubit.dart';
import '../cubit/catalog_search_state.dart';
import '../../domain/entities/catalog_search_results.dart' show CatalogSection;
import '../../../store/domain/entities/store_data.dart';
import '../../../store/presentation/widgets/store_market_card.dart';

// UI filters are independent of the server page cursors.
enum SearchFilter { all, products, markets, categories }

class SearchView extends StatefulWidget {
  const SearchView({super.key, this.initialFilter = SearchFilter.all});

  final SearchFilter initialFilter;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late SearchFilter _filter;
  final TextEditingController _queryController = TextEditingController();
  final ValueNotifier<String> _queryText = ValueNotifier('');
  Timer? _searchDebounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _queryText.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _queryText.value = _queryController.text;
    final query = _queryController.text.trim();
    if (query == _lastQuery) return;
    _lastQuery = query;
    _searchDebounce?.cancel();
    if (_queryController.text.trim().isEmpty) {
      context.read<CatalogSearchCubit>().search('');
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<CatalogSearchCubit>().search(_queryController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 900
                ? 920.0
                : constraints.maxWidth;

            return ValueListenableBuilder<AppPreferences>(
              valueListenable: AppPreferencesController.instance,
              builder: (context, preferences, _) {
                return BlocBuilder<CatalogSearchCubit, CatalogSearchState>(
                  buildWhen: (previous, current) =>
                      previous.runtimeType != current.runtimeType ||
                      previous.query != current.query ||
                      (previous is CatalogSearchFailure &&
                          current is CatalogSearchFailure &&
                          previous.message != current.message) ||
                      !identical(previous.results, current.results) ||
                      (previous is CatalogSearchReady &&
                          current is CatalogSearchReady &&
                          !identical(
                            previous.visibleProducts,
                            current.visibleProducts,
                          )),
                  builder: (context, discoveryState) => AnimatedBuilder(
                    animation: _queryText,
                    builder: (context, _) {
                      final query = _queryController.text.trim();
                      final results = discoveryState.results;
                      final productResults = _shows(SearchFilter.products)
                          ? (discoveryState is CatalogSearchReady
                                ? discoveryState.visibleProducts
                                : const <ProductData>[])
                          : <ProductData>[];
                      final categoryResults = _shows(SearchFilter.categories)
                          ? results.categories
                          : <CategoryData>[];
                      final marketResults = _shows(SearchFilter.markets)
                          ? results.markets
                          : <StoreMarketData>[];
                      final hasMoreProducts =
                          _shows(SearchFilter.products) &&
                          results.hasMoreProducts;
                      final hasResults =
                          productResults.isNotEmpty ||
                          categoryResults.isNotEmpty ||
                          marketResults.isNotEmpty ||
                          hasMoreProducts;
                      final isInitialLoading =
                          query.isNotEmpty &&
                          (discoveryState is CatalogSearchLoading ||
                              discoveryState.query != query);
                      final needsCity =
                          discoveryState is CatalogSearchNeedsCity;
                      final failure = discoveryState is CatalogSearchFailure
                          ? discoveryState
                          : null;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  28,
                                ),
                                sliver: SliverMainAxisGroup(
                                  slivers: [
                                    SliverToBoxAdapter(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const PageTopBar(
                                            title: 'Search',
                                            subtitle:
                                                'Products, shops and categories',
                                          ),
                                          const SizedBox(height: 18),
                                          _SearchInput(
                                            controller: _queryController,
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 12),
                                          _FilterBar(
                                            selected: _filter,
                                            onChanged: (filter) => setState(
                                              () => _filter = filter,
                                            ),
                                          ),
                                          const SizedBox(height: 18),

                                          if (isInitialLoading)
                                            _filter == SearchFilter.categories
                                                ? const AppCategorySkeletonGrid()
                                                : const AppProductSkeletonGrid()
                                          else if (needsCity)
                                            _EmptySearchState(
                                              query: '',
                                              isDark: isDark,
                                              title: 'Choose your city',
                                              message:
                                                  'So we can show shops available in your area.',
                                              onClear: () =>
                                                  Navigator.pop(context),
                                            )
                                          else if (failure != null)
                                            AppStateView(
                                              icon: AppIcons.warning_2,
                                              title: _failureTitle(
                                                failure.message,
                                              ),
                                              message: failure.message,
                                              actionLabel: 'Retry',
                                              color: AppColors.error,
                                              onAction: () => context
                                                  .read<CatalogSearchCubit>()
                                                  .search(query),
                                            )
                                          else if (query.isEmpty)
                                            _SearchStarter(
                                              onQuerySelected: (value) =>
                                                  _queryController.text = value,
                                            )
                                          else if (!hasResults)
                                            _EmptySearchState(
                                              query: query,
                                              isDark: isDark,
                                              onClear: _queryController.clear,
                                            )
                                          else ...[
                                            _SearchSummary(
                                              query: query,
                                              total:
                                                  productResults.length +
                                                  categoryResults.length +
                                                  marketResults.length,
                                              isDark: isDark,
                                            ),
                                            const SizedBox(height: 18),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (!isInitialLoading &&
                                        !needsCity &&
                                        failure == null &&
                                        query.isNotEmpty &&
                                        hasResults) ...[
                                      if (marketResults.isNotEmpty) ...[
                                        SliverToBoxAdapter(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _SectionTitle(
                                                title: 'Search shops',
                                                count: marketResults.length,
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                        SliverList.builder(
                                          itemCount: marketResults.length,
                                          itemBuilder: (context, index) {
                                            final market = marketResults[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: StoreMarketCard(
                                                market: market,
                                                keyPrefix: 'search',
                                                onTap: () => _openMarket(
                                                  context,
                                                  market,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 10),
                                        ),
                                      ],
                                      if (_shows(SearchFilter.markets) &&
                                          results.hasMoreMarkets)
                                        const SliverToBoxAdapter(
                                          child: _LoadMoreProducts(
                                            section: CatalogSection.markets,
                                          ),
                                        ),
                                      if (_shows(SearchFilter.categories) &&
                                          categoryResults.isNotEmpty) ...[
                                        SliverToBoxAdapter(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _SectionTitle(
                                                title: 'Search categories',
                                                count: categoryResults.length,
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                        SliverList.builder(
                                          itemCount: categoryResults.length,
                                          itemBuilder: (context, index) {
                                            final category =
                                                categoryResults[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: BrandCard(
                                                showBorder: true,
                                                brand: category.name,
                                                productCount:
                                                    category.marketCountLabel,
                                                logo: category.image,
                                                accentColor: Color(
                                                  category.accentColorValue,
                                                ),
                                                onTap: () => _openCategory(
                                                  context,
                                                  category,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 10),
                                        ),
                                      ],
                                      if (_shows(SearchFilter.categories) &&
                                          results.hasMoreCategories)
                                        const SliverToBoxAdapter(
                                          child: _LoadMoreProducts(
                                            section: CatalogSection.categories,
                                          ),
                                        ),
                                      if (_shows(SearchFilter.products) &&
                                          productResults.isNotEmpty) ...[
                                        SliverToBoxAdapter(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _SectionTitle(
                                                title: 'Products',
                                                count: productResults.length,
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                        ProductCardsSliver(
                                          products: productResults,
                                          idOf: productCardId,
                                          cardOf: productCardTileData,
                                        ),
                                      ],
                                      if (hasMoreProducts &&
                                          discoveryState is CatalogSearchReady)
                                        const SliverToBoxAdapter(
                                          child: _LoadMoreProducts(),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  bool _shows(SearchFilter filter) {
    return _filter == SearchFilter.all || _filter == filter;
  }

  String _failureTitle(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('unauthorized') ||
        normalized.contains('401') ||
        normalized.contains('login') ||
        normalized.contains('sign in')) {
      return 'Please login to search';
    }

    return 'Search failed';
  }

  void _openMarket(BuildContext context, StoreMarketData market) {
    Navigator.pushNamed(
      context,
      AppRoutes.brandProducts,
      arguments: BrandProductsRouteArgs(
        brand: market.name,
        logo: market.image,
        productCount: market.productCountLabel,
        marketId: market.id,
        classificationId: market.classificationId,
      ),
    );
  }

  void _openCategory(BuildContext context, CategoryData category) {
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
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller, required this.isDark});

  final TextEditingController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('catalog_search_field'),
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.tr('Search products, shops and categories...'),
        prefixIcon: const Icon(AppIcons.search_normal),
        suffixIcon: controller.text.isEmpty
            ? const Icon(AppIcons.filter_search, color: AppColors.primary)
            : Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: _SearchClearIconButton(onPressed: controller.clear),
              ),
        filled: true,
        fillColor: isDark ? AppColors.darkCardColor : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final SearchFilter selected;
  final ValueChanged<SearchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (SearchFilter.all, 'All'),
      (SearchFilter.products, 'Products'),
      (SearchFilter.markets, 'Search shops'),
      (SearchFilter.categories, 'Search categories'),
    ];

    return SizedBox(
      height: 38,
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == filters.length - 1 ? 0 : 8,
                ),
                child: Material(
                  color: selected == filters[index].$1
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    key: ValueKey('search_filter_${filters[index].$1.name}'),
                    onTap: () => onChanged(filters[index].$1),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.tr(filters[index].$2),
                            maxLines: 1,
                            style: TextStyle(
                              color: selected == filters[index].$1
                                  ? Colors.white
                                  : AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: AppFontSizes.body,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchStarter extends StatelessWidget {
  const _SearchStarter({required this.onQuerySelected});

  final ValueChanged<String> onQuerySelected;

  @override
  Widget build(BuildContext context) {
    const suggestions = ['مطاعم', 'خضار', 'صيدلية', 'ملابس', 'أجهزة إلكترونية'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Trending searches'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map((suggestion) {
                return ActionChip(
                  label: Text(context.tr(suggestion)),
                  avatar: const Icon(AppIcons.search_normal, size: 16),
                  onPressed: () => onQuerySelected(suggestion),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _SearchSummary extends StatelessWidget {
  const _SearchSummary({
    required this.query,
    required this.total,
    required this.isDark,
  });

  final String query;
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        Expanded(
          child: Text(
            context.isArabicLanguage
                ? '$total نتيجة لـ "$query"'
                : '$total result${total == 1 ? '' : 's'} for "$query"',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          context.tr('Best match'),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: mutedColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.tr(title),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          context.tr('$count'),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.query,
    required this.isDark,
    required this.onClear,
    this.title,
    this.message,
  });

  final String query;
  final bool isDark;
  final VoidCallback onClear;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.18 : 0.10,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                AppIcons.search_status,
                color: AppColors.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr(title ?? 'No results for "$query"'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(message ?? 'Try a product, shop or category name.'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedColor,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            _ClearSearchButton(
              onPressed: onClear,
              label: title == null ? 'Clear search' : 'Back',
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchClearIconButton extends StatelessWidget {
  const _SearchClearIconButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: context.tr('Clear search'),
      child: Material(
        color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: const SizedBox(
            width: 34,
            height: 34,
            child: Icon(Icons.close_rounded, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _ClearSearchButton extends StatelessWidget {
  const _ClearSearchButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.trash, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                context.tr(label),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMoreProducts extends StatelessWidget {
  const _LoadMoreProducts({this.section = CatalogSection.products});
  final CatalogSection section;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CatalogSearchCubit, CatalogSearchState, (bool, String?)>(
        selector: (state) =>
            state is CatalogSearchReady && state.moreSection == section
            ? (state.loadingMore, state.moreError)
            : (false, null),
        builder: (context, footer) => Column(
          children: [
            const SizedBox(height: 12),
            if (footer.$2 != null)
              Text(
                context.tr(footer.$2!),
                style: const TextStyle(color: AppColors.error),
              ),
            TextButton(
              onPressed: footer.$1
                  ? null
                  : () =>
                        context.read<CatalogSearchCubit>().loadSection(section),
              child: footer.$1
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      context.tr(
                        footer.$2 == null
                            ? (section == CatalogSection.products
                                  ? 'Load more products'
                                  : 'Load more')
                            : 'Retry',
                      ),
                    ),
            ),
          ],
        ),
      );
}
