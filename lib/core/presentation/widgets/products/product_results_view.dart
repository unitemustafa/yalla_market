import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../features/store/presentation/cubit/product_results_cubit.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../constants/app_colors.dart';
import '../../../localization/app_translations.dart';

import '../../../../features/store/domain/entities/product_data.dart';
import '../buttons/app_action_button.dart';
import '../layouts/grid_layout.dart';
import '../search/app_search_actions_bar.dart';
import '../states/app_state_view.dart';
import '../states/app_skeleton.dart';
import '../selection/category_selection.dart';
import 'product_cards/product_card_vertical.dart';
import 'product_card_tile.dart';
import 'product_cards_sliver.dart';
import 'product_card_tile_data.dart';
import 'product_sort_button.dart';

part 'product_results_controls.dart';

enum ProductResultsStatus { loading, ready, empty, error }

String productCardId(ProductData product) => product.id;
ProductCardTileData productCardTileData(ProductData p) => ProductCardTileData(
  id: p.id,
  image: p.image,
  title: p.title,
  brand: p.brand,
  price: p.price,
  slug: p.slug,
  defaultVariantId: p.defaultVariantId,
  marketId: p.marketId,
  oldPrice: p.oldPrice,
  discount: p.discount,
);

class ProductResultsView extends StatefulWidget {
  const ProductResultsView({
    super.key,
    required this.products,
    this.status = ProductResultsStatus.ready,
    this.sliver = false,
    this.subcategoryId,
    this.showSearch = true,
    this.useHomeSearchStyle = false,
    this.contentAfterSearch,
    this.controlsFooter,
    this.categorySelectionKey,
    this.pageSize = 10,
    this.initialSortOption = 'Name',
    this.initialQuery = '',
    this.searchFocusNode,
    this.maxCrossAxisCount = 6,
    this.gridMainAxisExtent = ProductCardVertical.compactGridMainAxisExtent,
    this.compactProductCards = true,
    this.showSummary = true,
    this.emptyTitle = 'No products found',
    this.emptyMessage = 'Try another search, category, or sorting option.',
    this.loadingMessage = 'Loading products...',
    this.errorTitle = 'Products could not load',
    this.errorMessage = 'Please check your connection and try again.',
    this.onRetry,
  }) : assert(pageSize > 0);

  final List<ProductData> products;
  final ProductResultsStatus status;

  /// Set when this widget is a direct sliver of a CustomScrollView.
  final bool sliver;
  final String? subcategoryId;
  final bool showSearch;
  final bool useHomeSearchStyle;
  final Widget? contentAfterSearch;
  final Widget? controlsFooter;
  final Object? categorySelectionKey;
  final int pageSize;
  final String initialSortOption;
  final String initialQuery;
  final FocusNode? searchFocusNode;
  final int maxCrossAxisCount;
  final double gridMainAxisExtent;
  final bool compactProductCards;
  final bool showSummary;
  final String emptyTitle;
  final String emptyMessage;
  final String loadingMessage;
  final String errorTitle;
  final String errorMessage;
  final VoidCallback? onRetry;

  @override
  State<ProductResultsView> createState() => _ProductResultsViewState();
}

class _ProductResultsViewState extends State<ProductResultsView> {
  late final TextEditingController _queryController;
  late String _sortOption;
  late final ProductResultsCubit _resultsCubit;

  static const _sortOptions = ['Name', 'Higher Price', 'Lower Price', 'Newest'];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
    _sortOption = _sortOptions.contains(widget.initialSortOption)
        ? widget.initialSortOption
        : 'Name';
    _resultsCubit = createProductResultsCubit();
    _queryController.addListener(_updateResults);

    _updateResults();
  }

  @override
  void didUpdateWidget(covariant ProductResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.products, widget.products) ||
        oldWidget.subcategoryId != widget.subcategoryId ||
        oldWidget.categorySelectionKey != widget.categorySelectionKey ||
        oldWidget.pageSize != widget.pageSize) {
      _updateResults();
    }
  }

  void _updateResults() {
    _resultsCubit.update(
      products: widget.products,
      query: _queryController.text,
      sortOption: _sortOption,

      pageSize: widget.pageSize,
      subcategoryId: widget.subcategoryId,
      categoryKey: widget.categorySelectionKey,
    );
  }

  void _selectSort(String value) {
    _sortOption = value;
    _updateResults();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _resultsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ProductResultsCubit, ProductResultsState>(
        bloc: _resultsCubit,
        builder: (context, state) {
          if (widget.sliver) return _buildResults(context, state);
          return AppLoadingTransition(
            isLoading:
                (widget.status == ProductResultsStatus.loading &&
                    widget.products.isEmpty) ||
                (state is ProductResultsReady &&
                    state.isPreparing &&
                    state.products.isEmpty),
            loading: AppProductSkeletonGrid(
              maxCrossAxisCount: widget.maxCrossAxisCount,
              mainAxisExtent: widget.gridMainAxisExtent,
            ),
            child: _buildResults(context, state),
          );
        },
      );

  Widget _box(Widget child) =>
      widget.sliver ? SliverToBoxAdapter(child: child) : child;

  Widget _buildResults(BuildContext context, ProductResultsState state) {
    if (widget.status == ProductResultsStatus.loading &&
            widget.products.isEmpty ||
        state is ProductResultsReady &&
            state.isPreparing &&
            state.products.isEmpty) {
      return _box(
        widget.sliver
            ? AppProductSkeletonGrid(
                maxCrossAxisCount: widget.maxCrossAxisCount,
                mainAxisExtent: widget.gridMainAxisExtent,
              )
            : const SizedBox.shrink(),
      );
    }
    if (widget.status == ProductResultsStatus.error ||
        state is ProductResultsFailure) {
      return _box(
        AppErrorState(
          title: widget.errorTitle,
          message: state is ProductResultsFailure
              ? state.message
              : widget.errorMessage,
          onRetry: state is ProductResultsFailure
              ? _updateResults
              : widget.onRetry,
        ),
      );
    }
    if (widget.status == ProductResultsStatus.empty ||
        (widget.products.isEmpty &&
            widget.controlsFooter == null &&
            widget.contentAfterSearch == null)) {
      return _box(
        AppEmptyState(
          title: widget.emptyTitle,
          message: widget.emptyMessage,
          icon: AppIcons.box,
        ),
      );
    }
    final ready = state as ProductResultsReady;
    final query = ready.query;
    final sorted = ready.products;
    final totalPages = ready.totalPages;
    final safePage = ready.page;
    Widget card(BuildContext context, int index) {
      final product = ready.itemAt(index);
      final child = ProductCardTile(
        key: ValueKey(product.id),
        product: productCardTileData(product),
        compact: widget.compactProductCards,
      );
      if (!widget.sliver || widget.categorySelectionKey == null) return child;
      // Only visible slots retain an outgoing card during the category fade.
      return CategoryContentTransition(
        key: ValueKey(index),
        selectionKey: ready.categoryKey ?? widget.categorySelectionKey!,
        fillPrevious: true,
        // Keep static card painting separate from the animated fade/transform.
        child: RepaintBoundary(child: child),
      );
    }

    final empty = AppEmptyState(
      title: widget.emptyTitle,
      message: query.isEmpty
          ? widget.emptyMessage
          : 'No products match "$query". Try a shorter keyword.',
      actionLabel: query.isEmpty ? null : 'Clear search',
      onAction: query.isEmpty ? null : _queryController.clear,
      icon: AppIcons.search_status,
    );
    final pagination = Column(
      children: [
        const SizedBox(height: 18),
        _PaginationControls(
          page: safePage,
          totalPages: totalPages,
          onPrevious: safePage == 0
              ? null
              : () => _resultsCubit.selectPage(safePage - 1),
          onNext: safePage >= totalPages - 1
              ? null
              : () => _resultsCubit.selectPage(safePage + 1),
        ),
      ],
    );
    final results = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sorted.isEmpty)
          empty
        else ...[
          GridLayout(
            itemCount: ready.itemCount,
            mainAxisExtent: widget.gridMainAxisExtent,
            maxCrossAxisCount: widget.maxCrossAxisCount,
            itemBuilder: card,
          ),
          if (totalPages > 1) pagination,
        ],
      ],
    );
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ready.preparationError != null)
          AppErrorState(
            title: widget.errorTitle,
            message: ready.preparationError!,
            onRetry: _updateResults,
          ),
        if (widget.showSearch) ...[
          if (widget.useHomeSearchStyle)
            AppSearchActionsBar(
              searchField: AppSearchField(
                key: const ValueKey('store_product_search_field'),
                hintText: 'Search products...',
                controller: _queryController,
                focusNode: widget.searchFocusNode,
                onChanged: (_) {},
              ),
              actions: [
                ProductSortButton.compact(
                  key: const ValueKey('store_product_filter_button'),
                  value: _sortOption,
                  options: _sortOptions,
                  onChanged: _selectSort,
                ),
              ],
            )
          else
            _ProductSearchField(
              controller: _queryController,
              onChanged: (_) {},
            ),
          const SizedBox(height: 12),
        ],
        if (widget.contentAfterSearch != null) ...[
          widget.contentAfterSearch!,
          const SizedBox(height: 14),
        ],
        if (widget.controlsFooter != null) ...[
          widget.controlsFooter!,
          const SizedBox(height: 14),
        ],
        if (!widget.useHomeSearchStyle) ...[
          ProductSortButton(
            value: _sortOption,
            options: _sortOptions,
            onChanged: _selectSort,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.showSummary) ...[
          _ProductResultsSummary(
            count: sorted.length,
            query: query,
            page: safePage + 1,
            totalPages: totalPages,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
    if (widget.sliver) {
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: controls),
          if (sorted.isEmpty)
            SliverToBoxAdapter(child: empty)
          else ...[
            ProductCardsSliver(
              products: ready.products,
              idOf: productCardId,
              cardOf: productCardTileData,
              start: ready.start,
              itemCount: ready.itemCount,
              mainAxisExtent: widget.gridMainAxisExtent,
              maxCrossAxisCount: widget.maxCrossAxisCount,
              compact: widget.compactProductCards,
              categoryKey: ready.categoryKey,
            ),
            if (totalPages > 1) SliverToBoxAdapter(child: pagination),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        controls,
        if (widget.categorySelectionKey == null)
          results
        else
          CategoryContentTransition(
            selectionKey: ready.categoryKey ?? widget.categorySelectionKey!,
            child: results,
          ),
      ],
    );
  }
}
