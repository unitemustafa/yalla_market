import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatters/product_pricing.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../../core/presentation/widgets/search/app_search_actions_bar.dart';
import '../../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../../core/routing/app_route_arguments.dart';
import '../../../../../core/routing/app_routes.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
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
                      hintText: 'Search the menu...',
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (_) => setState(() {}),
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
              child: Builder(
                builder: (context) {
                  final query = _controller.text.trim();
                  final products = widget.market.products
                      .where((product) => _matches(product, query))
                      .toList(growable: false);

                  if (products.isEmpty) {
                    return AppEmptyState(
                      title: 'No products found',
                      message: 'Try another product name.',
                      icon: AppIcons.search_status,
                    );
                  }

                  return ListView.separated(
                    key: const ValueKey('store_search_results'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.45),
                    ),
                    itemBuilder: (context, index) => _ProductSearchRow(
                      product: products[index],
                      onTap: () => _openProduct(products[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(ProductData product, String query) {
    final normalized = query.toLowerCase();
    if (normalized.isEmpty) return true;
    return product.matches(normalized) ||
        product.description.toLowerCase().contains(normalized);
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

class _ProductSearchRow extends StatelessWidget {
  const _ProductSearchRow({required this.product, required this.onTap});

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
                          product.description,
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
                      Text(
                        price,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
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
                  fit: BoxFit.cover,
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
