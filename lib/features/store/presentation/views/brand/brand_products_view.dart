import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../../core/config/app_environment.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../data/demo/demo_categories.dart';
import '../../../data/demo/demo_shops.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/brands/brand_card.dart';
import '../../../../../core/presentation/widgets/brands/brand_showcase.dart';
import '../../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../../core/presentation/widgets/products/product_results_view.dart';
import '../../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../../core/routing/app_route_arguments.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../domain/entities/product_data.dart';
import '../../../domain/entities/store_data.dart';
import '../../cubit/product_catalog_cubit.dart';
import '../../cubit/product_catalog_state.dart';
import '../../cubit/store_cubit.dart';
import '../../cubit/store_state.dart';

part 'brand_products_widgets.dart';

class BrandProductsView extends StatefulWidget {
  const BrandProductsView({
    super.key,
    required this.brand,
    required this.logo,
    required this.productCount,
    this.shopId,
    this.classificationId,
    this.marketId,
  });

  final String brand;
  final String logo;
  final String productCount;
  final String? shopId;
  final String? classificationId;
  final String? marketId;

  @override
  State<BrandProductsView> createState() => _BrandProductsViewState();
}

class _BrandProductsViewState extends State<BrandProductsView> {
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: BlocBuilder<StoreCubit, StoreState>(
          builder: (context, storeState) {
            return BlocBuilder<ProductCatalogCubit, ProductCatalogState>(
              builder: (context, catalogState) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: _buildContent(context, storeState, catalogState),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    StoreState storeState,
    ProductCatalogState state,
  ) {
    final storeContent = _buildStoreContent(context, storeState);
    if (storeContent != null) return storeContent;

    final isLocalShopCategory =
        AppEnvironment.useDemoRepositories &&
        MarketCategories.hasLocalShops(widget.brand);
    final selectedShopId = widget.shopId;

    if (state is ProductCatalogInitial || state is ProductCatalogLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTopBar(title: widget.brand, subtitle: widget.productCount),
          const SizedBox(height: 22),
          const AppLoadingState(message: 'Loading products...'),
        ],
      );
    }

    if (state is ProductCatalogFailure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTopBar(title: widget.brand, subtitle: widget.productCount),
          const SizedBox(height: 22),
          AppErrorState(
            title: 'Products could not load',
            message: state.message,
            onRetry: () =>
                context.read<ProductCatalogCubit>().loadProducts(force: true),
          ),
        ],
      );
    }

    if (state is ProductCatalogNeedsCity) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTopBar(title: widget.brand, subtitle: 'Choose your city'),
          const SizedBox(height: 22),
          const AppEmptyState(
            title: 'Choose your city',
            message: 'So we can show products available in your area.',
            icon: AppIcons.location,
          ),
        ],
      );
    }

    final readyState = state as ProductCatalogReady;
    if (isLocalShopCategory && selectedShopId != null) {
      return _buildShopMenu(context, readyState, selectedShopId);
    }

    if (isLocalShopCategory) {
      return _buildLocalShops(context, readyState);
    }

    return _buildProductList(context, readyState);
  }

  Widget? _buildStoreContent(BuildContext context, StoreState state) {
    final classificationId = widget.classificationId?.trim();
    final marketId = widget.marketId?.trim();
    if ((classificationId == null || classificationId.isEmpty) &&
        (marketId == null || marketId.isEmpty)) {
      return null;
    }

    final store = state.data;
    if (state is StoreLoading && store == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTopBar(title: widget.brand, subtitle: widget.productCount),
          const SizedBox(height: 22),
          const AppLoadingState(message: 'Loading stores...'),
        ],
      );
    }

    if (state is StoreFailure && store == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTopBar(title: widget.brand, subtitle: widget.productCount),
          const SizedBox(height: 22),
          AppErrorState(
            title: 'Store could not load',
            message: state.message,
            onRetry: () => context.read<StoreCubit>().loadStore(force: true),
          ),
        ],
      );
    }

    if (store == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTopBar(title: widget.brand, subtitle: widget.productCount),
          const SizedBox(height: 22),
          const AppLoadingState(message: 'Loading stores...'),
        ],
      );
    }

    if (marketId != null && marketId.isNotEmpty) {
      final market = _marketById(store, marketId);
      if (market == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTopBar(title: widget.brand, subtitle: widget.productCount),
            const SizedBox(height: 22),
            const AppEmptyState(
              title: 'Store unavailable',
              message: 'This store is not available for your current address.',
              icon: AppIcons.shop,
            ),
          ],
        );
      }
      return _buildApiMarketProducts(context, store, market);
    }

    if (classificationId != null && classificationId.isNotEmpty) {
      final classification = _classificationById(store, classificationId);
      final markets = store.marketsFor(classificationId);
      return _buildApiClassificationMarkets(context, classification, markets);
    }

    return null;
  }

  Widget _buildApiClassificationMarkets(
    BuildContext context,
    StoreClassificationData? classification,
    List<StoreMarketData> markets,
  ) {
    final title = classification?.name ?? widget.brand;
    final subtitle = markets.isEmpty
        ? widget.productCount
        : '${markets.length} store${markets.length == 1 ? '' : 's'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTopBar(title: title, subtitle: subtitle),
        const SizedBox(height: 18),
        BrandCard(
          showBorder: true,
          brand: title,
          logo: classification?.image ?? widget.logo,
          productCount: subtitle,
          accentColor: classification == null
              ? AppColors.primary
              : Color(classification.accentColorValue),
        ),
        const SizedBox(height: 22),
        if (markets.isEmpty)
          const AppEmptyState(
            title: 'No stores available',
            message: 'Stores will appear here when they cover your address.',
            icon: AppIcons.shop,
          )
        else
          ...markets.map(
            (market) => BrandShowcase(
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
                    classificationId: market.classificationId,
                    marketId: market.id,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildApiMarketProducts(
    BuildContext context,
    StoreData store,
    StoreMarketData market,
  ) {
    final classification = _classificationById(store, market.classificationId);
    final subtitle = [
      if (classification != null) classification.name,
      if (market.branch.trim().isNotEmpty) market.branch,
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTopBar(
          title: market.name,
          subtitle: subtitle.isEmpty ? market.productCountLabel : subtitle,
        ),
        const SizedBox(height: 18),
        ProductResultsView(
          products: market.products,
          status: ProductResultsStatus.ready,
          pageSize: 6,
          onRetry: () => context.read<StoreCubit>().loadStore(force: true),
          emptyTitle: 'No products available',
          emptyMessage: 'Products will appear here once this store is ready.',
        ),
      ],
    );
  }

  StoreClassificationData? _classificationById(StoreData store, String id) {
    final normalized = id.trim();
    for (final classification in store.classifications) {
      if (classification.id == normalized) return classification;
    }
    return null;
  }

  StoreMarketData? _marketById(StoreData store, String id) {
    final normalized = id.trim();
    for (final markets in store.marketsByClassificationId.values) {
      for (final market in markets) {
        if (market.id == normalized) return market;
      }
    }
    return null;
  }

  Widget _buildLocalShops(BuildContext context, ProductCatalogReady state) {
    final shops = MarketShops.byCategoryAndCity(widget.brand, state.city.slug);
    final cityName = context.tr(state.city.name);
    final subtitle = shops.isEmpty
        ? cityName
        : '${shops.length} محل في $cityName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTopBar(title: widget.brand, subtitle: subtitle),
        const SizedBox(height: 18),
        _LocalCategoryHeader(
          title: widget.brand,
          logo: widget.logo,
          cityName: cityName,
          shopCount: shops.length,
        ),
        const SizedBox(height: 18),
        if (shops.isEmpty)
          AppEmptyState(
            title: 'لا يوجد محلات في ${widget.brand}',
            message: 'هنضيف محلات في $cityName قريبًا.',
            icon: AppIcons.shop,
          )
        else
          ...shops.map(
            (shop) => _LocalShopCard(
              shop: shop,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.brandProducts,
                  arguments: BrandProductsRouteArgs(
                    brand: widget.brand,
                    logo: widget.logo,
                    productCount: shop.productCountLabel,
                    shopId: shop.id,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildShopMenu(
    BuildContext context,
    ProductCatalogReady state,
    String shopId,
  ) {
    final shop = MarketShops.byId(shopId);
    final cityName = context.tr(state.city.name);
    if (shop == null || shop.citySlug != state.city.slug) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTopBar(title: widget.brand, subtitle: cityName),
          const SizedBox(height: 22),
          const AppEmptyState(
            title: 'المحل غير متاح',
            message: 'المحل ده مش متاح في المنطقة المختارة حاليًا.',
            icon: AppIcons.shop,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTopBar(
          title: shop.name,
          subtitle: '${widget.brand} • ${context.tr(shop.cityName)}',
        ),
        const SizedBox(height: 18),
        ProductResultsView(
          products: shop.products,
          status: ProductResultsStatus.ready,
          pageSize: 6,
          emptyTitle: 'المنيو فاضي',
          emptyMessage: 'لسه مفيش منتجات متاحة من المحل ده.',
          loadingMessage: 'Loading menu...',
        ),
      ],
    );
  }

  Widget _buildProductList(BuildContext context, ProductCatalogReady state) {
    final products = state.products
        .where(
          (product) =>
              product.brand.trim().toLowerCase() ==
              widget.brand.trim().toLowerCase(),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTopBar(title: widget.brand, subtitle: widget.productCount),
        const SizedBox(height: 18),
        BrandCard(
          showBorder: true,
          brand: widget.brand,
          logo: widget.logo,
          productCount: widget.productCount,
        ),
        const SizedBox(height: 26),
        ProductResultsView(
          products: products.cast<ProductData>(),
          status: ProductResultsStatus.ready,
          pageSize: 4,
          onRetry: () =>
              context.read<ProductCatalogCubit>().loadProducts(force: true),
          emptyTitle: 'No ${widget.brand} items yet',
          emptyMessage:
              'This category is empty. Try another category or check back later.',
        ),
      ],
    );
  }
}
