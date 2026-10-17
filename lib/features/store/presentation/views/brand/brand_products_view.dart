import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../../core/presentation/widgets/states/app_skeleton.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../app/di/service_locator.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../../core/presentation/widgets/brands/brand_card.dart';
import '../../../../../core/presentation/widgets/products/product_results_view.dart';
import '../../../../../core/presentation/widgets/search/app_search_actions_bar.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../../app/routing/app_route_arguments.dart';
import '../../../../../app/routing/app_routes.dart';
import '../../../../../app/routing/shared_content_links.dart';
import '../../../../offers/domain/entities/offer_data.dart';
import '../../../../offers/presentation/cubit/offer_catalog_cubit.dart';
import '../../../../offers/presentation/cubit/offer_catalog_state.dart';
import '../../../domain/entities/product_data.dart';
import '../../../domain/entities/store_data.dart';
import '../../../domain/services/market_shop_catalog.dart';
import '../../cubit/product_catalog_cubit.dart';
import '../../cubit/product_catalog_state.dart';
import '../../cubit/store_cubit.dart';
import '../../cubit/store_state.dart';
import '../../widgets/market_storefront_hero.dart';
import '../../widgets/store_market_card.dart';
import 'brand_local_shop_card.dart';
import 'brand_store_sections.dart';
import 'market_type_rail.dart';
import '../../../../../core/presentation/widgets/selection/category_selection.dart';
import '../../../domain/entities/store_product_page.dart';
import '../../cubit/store_products_cubit.dart';
import '../../widgets/store_products_scope.dart';
import '../../widgets/store_products_sliver.dart';

export 'market_type_rail.dart';

List<ProductData> productsForStoreSubcategory(
  List<ProductData> products,
  String? subcategoryId,
) {
  final selected = subcategoryId?.trim() ?? '';
  if (selected.isEmpty) return List.unmodifiable(products);
  return products
      .where(
        (product) =>
            product.subcategories.any((item) => item.id == selected) ||
            product.subcategoryId == selected,
      )
      .toList(growable: false);
}

List<StoreMarketData> storesMatchingQuery(
  Iterable<StoreMarketData> stores,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return stores.toList(growable: false);
  return stores
      .where(
        (store) =>
            store.name.toLowerCase().contains(normalized) ||
            store.branch.toLowerCase().contains(normalized),
      )
      .toList(growable: false);
}

List<StoreMarketData> storesMatchingType(
  Iterable<StoreMarketData> stores,
  String? marketTypeId,
) {
  final selected = marketTypeId?.trim() ?? '';
  if (selected.isEmpty) return stores.toList(growable: false);
  return stores
      .where((store) => store.marketTypeIds.contains(selected))
      .toList(growable: false);
}

List<OfferData> offersForMarket(Iterable<OfferData> offers, String marketId) {
  final normalized = marketId.trim();
  if (normalized.isEmpty) return const [];
  final seen = <String>{};
  return offers
      .where((offer) => offer.belongsToMarket(normalized))
      .where((offer) => seen.add(offer.id))
      .toList(growable: false);
}

List<OfferData> offersForClassification(
  Iterable<OfferData> offers,
  String classificationId,
) {
  final normalized = classificationId.trim();
  if (normalized.isEmpty) return const [];
  final seen = <String>{};
  return offers
      .where((offer) => offer.belongsToClassification(normalized))
      .where((offer) => seen.add(offer.id))
      .toList(growable: false);
}

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
  String? _selectedSubcategoryId;
  String? _selectedMarketTypeId;
  final TextEditingController _storeSearchController = TextEditingController();
  String _storeQuery = '';
  final ScrollController _marketScrollController = ScrollController();
  final GlobalKey _productsAnchor = GlobalKey();
  StoreProductsCubit? _marketProductsCubit;

  MarketShopCatalog get _marketCatalog => sl<MarketShopCatalog>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final storeCubit = context.read<StoreCubit>();
      final offerCubit = context.read<OfferCatalogCubit>();
      await storeCubit.loadStore();
      if (!mounted) return;
      final marketId = widget.marketId?.trim() ?? '';
      if (marketId.isNotEmpty) {
        await storeCubit.ensureMarket(marketId);
      } else {
        final classificationId = widget.classificationId?.trim() ?? '';
        if (classificationId.isNotEmpty) {
          await storeCubit.ensureClassification(classificationId);
        }
      }
      offerCubit.loadOffers();
    });
  }

  @override
  void didUpdateWidget(covariant BrandProductsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketId != widget.marketId) {
      _selectedSubcategoryId = null;
      final marketId = widget.marketId?.trim() ?? '';
      if (marketId.isNotEmpty) {
        context.read<StoreCubit>().ensureMarket(marketId);
      }
    }
    if (oldWidget.classificationId != widget.classificationId) {
      _storeSearchController.clear();
      _storeQuery = '';
      _selectedMarketTypeId = null;
      final classificationId = widget.classificationId?.trim() ?? '';
      if (classificationId.isNotEmpty) {
        context.read<StoreCubit>().ensureClassification(classificationId);
      }
    }
  }

  @override
  void dispose() {
    _storeSearchController.dispose();
    _marketScrollController.dispose();
    super.dispose();
  }

  void _openStoreSearch(StoreMarketData market) {
    Navigator.pushNamed(
      context,
      AppRoutes.storeSearch,
      arguments: StoreSearchRouteArgs(market: market),
    );
  }

  Future<void> _shareMarket(StoreMarketData market) async {
    final link = SharedContentLinks.market(market.id);
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: market.name,
          text: '${market.name}\n$link',
          sharePositionOrigin: Rect.fromCenter(
            center: MediaQuery.sizeOf(context).center(Offset.zero),
            width: 1,
            height: 1,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      CustomSnackBar.showError(
        context: context,
        title: 'Could not share store',
        message: 'Please try again.',
      );
    }
  }

  Future<void> _refreshContent() async {
    final activeMarketId = widget.marketId?.trim() ?? '';
    if (activeMarketId.isNotEmpty) {
      await Future.wait([
        context.read<StoreCubit>().ensureMarket(activeMarketId, force: true),
        context.read<OfferCatalogCubit>().loadOffers(force: true),
        if (_marketProductsCubit != null) _marketProductsCubit!.refresh(),
      ]);
      return;
    }
    await Future.wait([
      context.read<StoreCubit>().loadStore(force: true),
      context.read<ProductCatalogCubit>().loadProducts(force: true),
      context.read<OfferCatalogCubit>().loadOffers(force: true),
    ]);
    if (!mounted) return;
    final storeCubit = context.read<StoreCubit>();
    final marketId = widget.marketId?.trim() ?? '';
    if (marketId.isNotEmpty) {
      await storeCubit.ensureMarket(marketId);
      return;
    }
    final classificationId = widget.classificationId?.trim() ?? '';
    if (classificationId.isNotEmpty) {
      await storeCubit.ensureClassification(classificationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMarketPage = widget.marketId?.trim().isNotEmpty == true;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    final page = Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: !isMarketPage,
        child: BlocBuilder<StoreCubit, StoreState>(
          builder: (context, storeState) {
            if (isMarketPage ||
                widget.classificationId?.trim().isNotEmpty == true) {
              return BlocSelector<
                OfferCatalogCubit,
                OfferCatalogState,
                List<OfferData>
              >(
                selector: (state) => state.offers,
                builder: (context, offers) => _buildStoreViewport(
                  context,
                  storeState,
                  offers,
                  isMarketPage,
                ),
              );
            }
            return BlocBuilder<ProductCatalogCubit, ProductCatalogState>(
              builder: (context, catalogState) {
                return BlocBuilder<OfferCatalogCubit, OfferCatalogState>(
                  builder: (context, offerState) {
                    return AppRefreshIndicator(
                      onRefresh: _refreshContent,
                      child: SingleChildScrollView(
                        physics: AppRefreshIndicator.scrollPhysics,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: isMarketPage
                            ? const EdgeInsets.only(bottom: 28)
                            : const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        child: _buildContent(
                          context,
                          storeState,
                          catalogState,
                          offerState.offers,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );

    if (!isMarketPage) return page;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: page,
    );
  }

  Widget _buildStoreViewport(
    BuildContext context,
    StoreState state,
    List<OfferData> offers,
    bool isMarketPage,
  ) {
    final store = state.data;
    final market = store == null
        ? null
        : _marketById(store, widget.marketId ?? '');
    final classificationId = widget.classificationId?.trim();
    final Widget content;
    if (market != null) {
      content = _buildApiMarketProducts(
        context,
        store!,
        market,
        offersForMarket(offers, market.id),
      );
    } else if (!isMarketPage && store != null && classificationId != null) {
      content = _buildApiClassificationMarkets(
        context,
        _classificationById(store, classificationId),
        store.marketsFor(classificationId),
      );
    } else {
      content = SliverToBoxAdapter(
        child: _buildStoreContent(context, state, offers)!,
      );
    }
    return AppRefreshIndicator(
      onRefresh: _refreshContent,
      child: CustomScrollView(
        controller: isMarketPage ? _marketScrollController : null,
        physics: AppRefreshIndicator.scrollPhysics,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: isMarketPage
                ? const EdgeInsets.only(bottom: 28)
                : const EdgeInsets.fromLTRB(16, 12, 16, 28),
            sliver: content,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    StoreState storeState,
    ProductCatalogState state,
    List<OfferData> offers,
  ) {
    final storeContent = _buildStoreContent(context, storeState, offers);
    if (storeContent != null) return storeContent;

    final isLocalShopCategory = _marketCatalog.categoryHasLocalShops(
      widget.brand,
    );
    final selectedShopId = widget.shopId;

    if (state is ProductCatalogInitial || state is ProductCatalogLoading) {
      return AppContentReveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTopBar(
              titleMaxLines: null,
              title: widget.brand,
              subtitle: widget.productCount,
            ),
            const AppRefreshAnchor(),
            const SizedBox(height: 22),
            const AppProductSkeletonGrid(),
          ],
        ),
      );
    }

    if (state is ProductCatalogFailure) {
      return AppContentReveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTopBar(
              titleMaxLines: null,
              title: widget.brand,
              subtitle: widget.productCount,
            ),
            const AppRefreshAnchor(),
            const SizedBox(height: 22),
            AppErrorState(
              title: 'Products could not load',
              message: state.message,
              onRetry: () =>
                  context.read<ProductCatalogCubit>().loadProducts(force: true),
            ),
          ],
        ),
      );
    }

    if (state is ProductCatalogNeedsCity) {
      return AppContentReveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTopBar(
              titleMaxLines: null,
              title: widget.brand,
              subtitle: 'Choose your city',
            ),
            const AppRefreshAnchor(),
            const SizedBox(height: 22),
            const AppEmptyState(
              title: 'Choose your city',
              message: 'So we can show products available in your area.',
              icon: AppIcons.location,
            ),
          ],
        ),
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

  Widget? _buildStoreContent(
    BuildContext context,
    StoreState state,
    List<OfferData> offers,
  ) {
    final classificationId = widget.classificationId?.trim();
    final marketId = widget.marketId?.trim();
    if ((classificationId == null || classificationId.isEmpty) &&
        (marketId == null || marketId.isEmpty)) {
      return null;
    }

    final store = state.data;
    if (state is StoreLoading && store == null) {
      return AppContentReveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTopBar(
              titleMaxLines: null,
              title: widget.brand,
              subtitle: widget.productCount,
            ),
            const AppRefreshAnchor(),
            const SizedBox(height: 22),
            const AppSkeletonList(rowHeight: 150),
          ],
        ),
      );
    }

    if (state is StoreFailure && store == null) {
      return AppContentReveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTopBar(
              titleMaxLines: null,
              title: widget.brand,
              subtitle: widget.productCount,
            ),
            const AppRefreshAnchor(),
            const SizedBox(height: 22),
            AppErrorState(
              title: 'Store could not load',
              message: state.message,
              onRetry: () => context.read<StoreCubit>().loadStore(force: true),
            ),
          ],
        ),
      );
    }

    if (store == null) {
      return AppContentReveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTopBar(
              titleMaxLines: null,
              title: widget.brand,
              subtitle: widget.productCount,
            ),
            const AppRefreshAnchor(),
            const SizedBox(height: 22),
            const AppSkeletonList(rowHeight: 150),
          ],
        ),
      );
    }

    if (marketId != null && marketId.isNotEmpty) {
      final market = _marketById(store, marketId);
      if (market == null) {
        return AppContentReveal(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageTopBar(
                titleMaxLines: null,
                title: widget.brand,
                subtitle: widget.productCount,
              ),
              const AppRefreshAnchor(),
              const SizedBox(height: 22),
              const AppEmptyState(
                title: 'Store unavailable',
                message:
                    'This store is not available for your current address.',
                icon: AppIcons.shop,
              ),
            ],
          ),
        );
      }
      return _buildApiMarketProducts(
        context,
        store,
        market,
        offersForMarket(offers, market.id),
      );
    }

    if (classificationId != null && classificationId.isNotEmpty) {
      final classification = _classificationById(store, classificationId);
      final markets = store.marketsFor(classificationId);
      // Offer banners are temporarily hidden on classification pages.
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
    final availableMarketTypes = (classification?.marketTypes ?? const [])
        .where(
          (type) =>
              markets.any((market) => market.marketTypeIds.contains(type.id)),
        )
        .toList(growable: false);
    final effectiveTypeId =
        availableMarketTypes.any((type) => type.id == _selectedMarketTypeId)
        ? _selectedMarketTypeId
        : availableMarketTypes.firstOrNull?.id;
    final visibleMarkets = storesMatchingType(
      storesMatchingQuery(markets, _storeQuery),
      effectiveTypeId,
    );

    return SliverContentReveal(
      child: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageTopBar(
                  titleMaxLines: null,
                  title: title,
                  subtitle: subtitle,
                ),
                const AppRefreshAnchor(),
                const SizedBox(height: 18),
                AppSearchField(
                  key: const ValueKey('category_store_search_field'),
                  hintText: 'Search stores...',
                  controller: _storeSearchController,
                  onChanged: (value) => setState(() => _storeQuery = value),
                ),
                if (availableMarketTypes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  MarketTypeRail(
                    types: availableMarketTypes,
                    selectedId: effectiveTypeId,
                    onSelected: (value) {
                      setState(() => _selectedMarketTypeId = value);
                    },
                  ),
                ],
                const SizedBox(height: 18),
              ],
            ),
          ),
          if (visibleMarkets.isEmpty)
            SliverToBoxAdapter(
              child: CategoryContentTransition(
                selectionKey: effectiveTypeId ?? 'all',
                child: AppEmptyState(
                  title: _storeQuery.trim().isEmpty
                      ? 'No stores available'
                      : 'No stores found',
                  message: _storeQuery.trim().isEmpty
                      ? 'Stores will appear here when they cover your address.'
                      : 'Try a different store name.',
                  icon: _storeQuery.trim().isEmpty
                      ? AppIcons.shop
                      : AppIcons.search_status,
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: visibleMarkets.length,
              itemBuilder: (context, index) {
                final market = visibleMarkets[index];
                return CategoryContentTransition(
                  selectionKey: effectiveTypeId ?? 'all',
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StoreMarketCard(
                      key: ValueKey('classification_store_${market.id}'),
                      market: market,
                      keyPrefix: 'classification_store',
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
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildApiMarketProducts(
    BuildContext context,
    StoreData store,
    StoreMarketData market,
    List<OfferData> offers,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final categories = market.subcategories;
    final selectedId =
        categories.any((category) => category.id == _selectedSubcategoryId)
        ? _selectedSubcategoryId
        : categories.firstOrNull?.id;
    final selectedCategory = selectedId == null
        ? null
        : categories.firstWhere((category) => category.id == selectedId);
    final categoryDescription = selectedCategory?.localizedDescription(
      languageCode,
    );
    final controlsFooter = categories.isEmpty
        ? null
        : StoreSubcategoryRail(
            categories: categories,
            selectedId: selectedId,
            languageCode: languageCode,
            categoryDescription: categoryDescription,
            onSelected: (categoryId) {
              setState(() => _selectedSubcategoryId = categoryId);
              _scrollToProducts();
            },
          );

    return SliverContentReveal(
      child: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: MarketStorefrontHero(
              market: market,
              onBack: Navigator.of(context).pop,
              onSearch: () => _openStoreSearch(market),
              onShare: () => _shareMarket(market),
            ),
          ),
          const SliverToBoxAdapter(child: AppRefreshAnchor()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            sliver: StoreProductsScope(
              marketId: market.id,
              scrollController: _marketScrollController,
              subcategoryId: selectedId,
              sort: StoreProductSort.name,
              builder: (context, cubit) {
                _marketProductsCubit = cubit;
                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        key: _productsAnchor,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (offers.isNotEmpty) ...[
                            StoreOfferSection(offers: offers),
                            const SizedBox(height: 14),
                          ],
                          if (controlsFooter != null) ...[
                            controlsFooter,
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),
                    StoreProductsSliver(
                      categoryKey: selectedId ?? 'all',
                      emptyTitle: selectedCategory == null
                          ? 'No products available'
                          : 'No products in this section',
                      emptyMessage: selectedCategory == null
                          ? 'Products will appear here once this store is ready.'
                          : 'Try another section or choose All.',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToProducts() {
    final anchor = _productsAnchor.currentContext;
    if (anchor != null) {
      unawaited(
        Scrollable.ensureVisible(
          anchor,
          duration: const Duration(milliseconds: 200),
        ),
      );
    }
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
    final shops = _marketCatalog.byCategoryAndCity(
      widget.brand,
      state.city.slug,
    );
    final cityName = context.tr(state.city.name);
    final subtitle = shops.isEmpty
        ? cityName
        : '${shops.length} محل في $cityName';

    return AppContentReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTopBar(
            titleMaxLines: null,
            title: widget.brand,
            subtitle: subtitle,
          ),
          const AppRefreshAnchor(),
          const SizedBox(height: 18),
          LocalCategoryHeader(
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
              (shop) => LocalShopCard(
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
      ),
    );
  }

  Widget _buildShopMenu(
    BuildContext context,
    ProductCatalogReady state,
    String shopId,
  ) {
    final shop = _marketCatalog.byId(shopId);
    final cityName = context.tr(state.city.name);
    if (shop == null || shop.citySlug != state.city.slug) {
      return AppContentReveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTopBar(
              titleMaxLines: null,
              title: widget.brand,
              subtitle: cityName,
            ),
            const AppRefreshAnchor(),
            const SizedBox(height: 22),
            const AppEmptyState(
              title: 'المحل غير متاح',
              message: 'المحل ده مش متاح في المنطقة المختارة حاليًا.',
              icon: AppIcons.shop,
            ),
          ],
        ),
      );
    }

    return AppContentReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTopBar(
            titleMaxLines: null,
            title: shop.name,
            subtitle: '${widget.brand} • ${context.tr(shop.cityName)}',
          ),
          const AppRefreshAnchor(),
          const SizedBox(height: 18),
          ProductResultsView(
            products: shop.products,
            status: ProductResultsStatus.ready,
            emptyTitle: 'المنيو فاضي',
            emptyMessage: 'لسه مفيش منتجات متاحة من المحل ده.',
          ),
        ],
      ),
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

    return AppContentReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTopBar(
            titleMaxLines: null,
            title: widget.brand,
            subtitle: widget.productCount,
          ),
          const AppRefreshAnchor(),
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
            onRetry: () =>
                context.read<ProductCatalogCubit>().loadProducts(force: true),
            emptyTitle: 'No ${widget.brand} items yet',
            emptyMessage:
                'This category is empty. Try another category or check back later.',
          ),
        ],
      ),
    );
  }
}
