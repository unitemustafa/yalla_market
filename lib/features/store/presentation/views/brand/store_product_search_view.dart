import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/store_products_cubit.dart';
import '../../widgets/store_products_scope.dart';
import '../../widgets/store_products_footer.dart';
import '../../../domain/entities/store_product_page.dart';
import '../../../../../core/presentation/widgets/app_refresh_indicator.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/formatters/product_pricing.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../../core/presentation/widgets/search/app_search_actions_bar.dart';
import '../../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../../core/presentation/widgets/texts/green_currency_price.dart';
import '../../../../../app/routing/app_route_arguments.dart';
import '../../../../../app/routing/app_routes.dart';
import '../../../domain/entities/product_data.dart';
import '../../../domain/entities/store_data.dart';

class StoreProductSearchView extends StatefulWidget {
  const StoreProductSearchView({super.key, required this.market});

  final StoreMarketData market;

  @override
  State<StoreProductSearchView> createState() => _StoreProductSearchViewState();
}

class _StoreProductSearchViewState extends State<StoreProductSearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _focusNode.unfocus();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF8F9FB);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  Expanded(
                    child: AppSearchField(
                      key: const ValueKey('store_search_page_field'),
                      hintText: context.tr('Search the menu...'),
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _search,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _BackButton(onTap: Navigator.of(context).pop),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
            ),
            Expanded(
              child: StoreProductsScope(
                marketId: widget.market.id,
                query: _query,
                sort: StoreProductSort.newest,
                scrollController: _scrollController,
                builder: (context, cubit) => AppRefreshIndicator(
                  onRefresh: cubit.refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    key: const ValueKey('store_search_results'),
                    physics: AppRefreshIndicator.scrollPhysics,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      BlocSelector<
                        StoreProductsCubit,
                        StoreProductsState,
                        (List<ProductData>, bool, String?, bool)
                      >(
                        selector: (s) => (
                          s.visibleProducts,
                          s.isLoading && s.products.isEmpty,
                          s.products.isEmpty ? s.error : null,
                          s.hasMore,
                        ),
                        builder: (context, content) {
                          if (content.$2) {
                            return const SliverToBoxAdapter(
                              child: AppLoadingState(),
                            );
                          }
                          if (content.$3 != null) {
                            return SliverToBoxAdapter(
                              child: AppErrorState(
                                title: 'Could not load products',
                                message: content.$3!,
                                onRetry: cubit.retry,
                              ),
                            );
                          }
                          final products = content.$1;
                          if (products.isEmpty) {
                            if (content.$4) {
                              return const SliverToBoxAdapter(
                                child: SizedBox.shrink(),
                              );
                            }
                            return SliverToBoxAdapter(
                              child: AppEmptyState(
                                title: context.tr('No products found'),
                                message: context.tr(
                                  'Try another product name.',
                                ),
                                icon: AppIcons.search_status,
                              ),
                            );
                          }
                          final indices = {
                            for (var i = 0; i < products.length; i++)
                              products[i].id: i * 2,
                          };
                          return SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index.isOdd) {
                                    return Divider(
                                      height: 1,
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withValues(alpha: 0.45),
                                    );
                                  }
                                  final product = products[index ~/ 2];
                                  return _ProductSearchRow(
                                    key: ValueKey(product.id),
                                    product: product,
                                    onTap: () => _openProduct(product),
                                  );
                                },
                                childCount: products.length * 2 - 1,
                                findChildIndexCallback: (key) =>
                                    key is ValueKey<String>
                                    ? indices[key.value]
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                      const SliverToBoxAdapter(child: StoreProductsFooter()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final query = _controller.text.trim();
      if (query == _query) return;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      setState(() => _query = query);
    });
  }

  void _openProduct(ProductData product) {
    _focusNode.unfocus();
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: ProductDetailRouteArgs(
        image: product.image,
        title: product.title,
        brand: product.brand,
        price: product.price,
        productId: product.id,
        productSlug: product.slug,
        oldPrice: product.oldPrice,
        discount: product.discount,
        initialVariantId: product.defaultVariantId,
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkCardColor : Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            isRtl ? AppIcons.arrow_right_3 : AppIcons.arrow_left_2,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _ProductSearchRow extends StatefulWidget {
  const _ProductSearchRow({
    super.key,
    required this.product,
    required this.onTap,
  });

  final ProductData product;
  final VoidCallback onTap;
  @override
  State<_ProductSearchRow> createState() => _ProductSearchRowState();
}

class _ProductSearchRowState extends State<_ProductSearchRow> {
  late Widget _content;
  void _update() => _content = _ProductSearchRowContent(
    product: widget.product,
    onTap: widget.onTap,
  );
  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(_ProductSearchRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.product, widget.product)) _update();
  }

  @override
  Widget build(BuildContext context) => _content;
}

class _ProductSearchRowContent extends StatelessWidget {
  const _ProductSearchRowContent({required this.product, required this.onTap});

  final ProductData product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final price = ProductPricing.formattedPrice(
      product.price,
      discount: product.discount,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 3, end: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(product.title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          context.tr(product.description),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: muted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      GreenCurrencyPrice(
                        price: price,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: AppFontSizes.body,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 112,
                height: 112,
                child: AppImage(
                  source: product.image,
                  fallbackType: AppImagePlaceholderType.product,
                  role: AppImageRole.product,
                  borderRadius: BorderRadius.circular(14),
                  cacheWidth: 340,
                  cacheHeight: 340,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
