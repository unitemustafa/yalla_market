import 'package:yalla_market/app/routing/catalog_route_container.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/states/app_skeleton.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/presentation/widgets/products/product_cards_sliver.dart';
import '../../../../core/presentation/widgets/products/product_card_tile_data.dart';
import '../../../../core/presentation/widgets/layouts/horizontal_card_layout.dart';
import '../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../core/presentation/widgets/products/cart_counter_icon.dart';
import '../../../../app/routing/app_route_arguments.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../store/presentation/widgets/store_market_card.dart';
import '../../domain/entities/wishlist_item.dart';
import '../cubit/wishlist_cubit.dart';
import '../cubit/wishlist_state.dart';
import '../cubit/market_wishlist_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'wishlist_widgets.dart';

class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<MarketWishlistCubit, MarketWishlistState>(
      listenWhen: (previous, current) =>
          previous.errorRevision != current.errorRevision,
      listener: (context, state) {
        if (state.errorMessage?.isNotEmpty == true) {
          CustomSnackBar.showError(
            context: context,
            title: 'Could not update favorite stores',
            message: state.errorMessage,
          );
        }
      },
      child: BlocListener<WishlistCubit, List<WishlistItem>>(
        listenWhen: (previous, current) =>
            current is WishlistState &&
            current.errorMessage != null &&
            (previous is! WishlistState ||
                previous.errorRevision != current.errorRevision),
        listener: (context, state) {
          if (state is WishlistState) {
            CustomSnackBar.showError(
              context: context,
              title: 'Could not update favorite products',
              message: state.errorMessage,
            );
          }
        },
        child: Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : const Color(0xFFF7F8FB),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _WishlistTopBar(isDark: isDark),
                ),
                Expanded(
                  child: AppRefreshIndicator(
                    onRefresh: () => Future.wait([
                      context.read<WishlistCubit>().refresh(),
                      context.read<MarketWishlistCubit>().refresh(),
                    ]),
                    child: const _WishlistBody(),
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

class _WishlistBody extends StatelessWidget {
  const _WishlistBody();

  @override
  Widget build(BuildContext context) {
    final products = context.select((WishlistCubit cubit) {
      final state = cubit.state;
      final hasMore = state is WishlistState && state.hasMore;
      final loading =
          state is WishlistState && state.loading && !state.hasLoaded;
      return (hasContent: state.isNotEmpty || hasMore, loading: loading);
    });
    final stores = context.select((MarketWishlistCubit cubit) {
      final state = cubit.state;
      return (
        hasContent: state.items.isNotEmpty || state.hasMore,
        loading: state.loading && !state.hasLoaded,
      );
    });

    if (products.hasContent || stores.hasContent) {
      return const AppContentReveal(
        child: CustomScrollView(
          physics: AppRefreshIndicator.scrollPhysics,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(child: AppRefreshAnchor()),
                  _FavoriteProductsSliver(),
                  _FavoriteSectionGap(),
                  _FavoriteStoresSliver(),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (products.loading || stores.loading) {
      return const SingleChildScrollView(
        physics: AppRefreshIndicator.scrollPhysics,
        child: Column(
          children: [
            AppRefreshAnchor(),
            Padding(
              padding: EdgeInsets.all(16),
              child: AppSkeletonList(rowHeight: 150),
            ),
          ],
        ),
      );
    }
    return _EmptyWishlistView(
      isDark: Theme.of(context).brightness == Brightness.dark,
      onExplorePressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.navigationMenu,
          (route) => false,
          arguments: const NavigationMenuRouteArgs(initialIndex: 1),
        );
      },
    );
  }
}

class _FavoriteProductsSliver extends StatelessWidget {
  const _FavoriteProductsSliver();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WishlistCubit, List<WishlistItem>>(
        builder: (context, wishlist) => SliverMainAxisGroup(
          slivers: [
            if (wishlist is WishlistState &&
                wishlist.loading &&
                !wishlist.hasLoaded &&
                wishlist.isEmpty)
              const SliverToBoxAdapter(
                child: Column(
                  children: [AppProductSkeletonGrid(), SizedBox(height: 18)],
                ),
              ),
            if (wishlist.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Column(
                  children: [
                    _WishlistSectionTitle(
                      title: 'Favorite products',
                      icon: AppIcons.heart5,
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
              ProductCardsSliver<WishlistItem>(
                key: const ValueKey('wishlist_products_grid'),
                products: wishlist,
                idOf: _wishlistProductId,
                cardOf: _wishlistProductCardData,
              ),
            ],
            if (wishlist is WishlistState &&
                (wishlist.hasMore || wishlist.moreError != null))
              SliverToBoxAdapter(
                child: _FavoriteLoadMore(
                  key: const ValueKey('wishlist_products_load_more'),
                  loading: wishlist.loading || wishlist.loadingMore,
                  error: wishlist.moreError,
                  onPressed: context.read<WishlistCubit>().loadMore,
                ),
              ),
          ],
        ),
      );
}

class _FavoriteSectionGap extends StatelessWidget {
  const _FavoriteSectionGap();

  @override
  Widget build(BuildContext context) {
    final hasProducts = context.select(
      (WishlistCubit cubit) => cubit.state.isNotEmpty,
    );
    final hasStores = context.select(
      (MarketWishlistCubit cubit) => cubit.state.items.isNotEmpty,
    );
    return SliverToBoxAdapter(
      child: SizedBox(height: hasProducts && hasStores ? 28 : 0),
    );
  }
}

class _FavoriteStoresSliver extends StatelessWidget {
  const _FavoriteStoresSliver();

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<MarketWishlistCubit, MarketWishlistState>(
    builder: (context, wishlist) => SliverMainAxisGroup(
      slivers: [
        if (wishlist.loading && !wishlist.hasLoaded && wishlist.items.isEmpty)
          const SliverToBoxAdapter(
            child: Column(
              children: [SizedBox(height: 18), AppSkeletonList(rowHeight: 150)],
            ),
          ),
        if (wishlist.items.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WishlistSectionTitle(
                  title: 'Favorite stores',
                  icon: AppIcons.shop5,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: StoreMarketCard.height,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = compactHorizontalCardWidth(
                        constraints.maxWidth,
                      );
                      return ListView.separated(
                        key: const ValueKey(
                          'wishlist_stores_horizontal_slider',
                        ),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: wishlist.items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final market = wishlist.items[index];
                          return SizedBox(
                            width: cardWidth,
                            child: CatalogRouteContainer(
                              key: ValueKey(market.id),
                              settings: RouteSettings(
                                name: AppRoutes.brandProducts,
                                arguments: BrandProductsRouteArgs(
                                  brand: market.name,
                                  logo: market.image,
                                  productCount: market.productCountLabel,
                                  classificationId: market.classificationId,
                                  marketId: market.id,
                                ),
                              ),
                              closedColor: Colors.transparent,
                              closedBuilder: (context, open) => StoreMarketCard(
                                key: ValueKey('wishlist_store_${market.id}'),
                                market: market,
                                keyPrefix: 'wishlist_store',
                                onTap: open,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        if (wishlist.hasMore || wishlist.moreError != null)
          SliverToBoxAdapter(
            child: _FavoriteLoadMore(
              key: const ValueKey('wishlist_stores_load_more'),
              loading: wishlist.loading || wishlist.loadingMore,
              error: wishlist.moreError,
              onPressed: context.read<MarketWishlistCubit>().loadMore,
            ),
          ),
      ],
    ),
  );
}
