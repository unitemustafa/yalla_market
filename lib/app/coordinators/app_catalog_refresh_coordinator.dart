import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/offers/presentation/cubit/offer_catalog_cubit.dart';
import '../../features/store/presentation/cubit/product_catalog_cubit.dart';
import '../../features/store/presentation/cubit/product_discovery_cubit.dart';
import '../../features/store/presentation/cubit/store_cubit.dart';
import '../routing/app_route_arguments.dart';
import '../routing/app_routes.dart';

abstract final class AppCatalogRefreshCoordinator {
  static void invalidateAll(BuildContext context) {
    context.read<HomeCubit>().invalidate();
    context.read<ProductCatalogCubit>().invalidate();
    context.read<ProductDiscoveryCubit>().invalidate();
    context.read<StoreCubit>().invalidate();
    context.read<OfferCatalogCubit>().invalidate();
  }

  static void resetForRegion(BuildContext context) {
    context.read<HomeCubit>().clearSession();
    context.read<ProductCatalogCubit>().clearSession();
    context.read<ProductDiscoveryCubit>().clearSession();
    context.read<StoreCubit>().clearSession();
    context.read<OfferCatalogCubit>().clearSession();
  }

  static bool handles(String? route) => const {
    AppRoutes.allProducts,
    AppRoutes.productCategoryCampaign,
    AppRoutes.latestStores,
    AppRoutes.brandProducts,
    AppRoutes.storeSearch,
    AppRoutes.categories,
    AppRoutes.search,
  }.contains(route);

  static Future<void> refreshRoute(
    BuildContext context,
    RouteSettings settings,
  ) async {
    switch (settings.name) {
      case AppRoutes.allProducts:
        final args = settings.arguments as AllProductsRouteArgs?;
        if (args?.collection == ProductCollectionType.latest) {
          await context.read<ProductCatalogCubit>().loadProducts();
        } else {
          await context.read<HomeCubit>().loadHome();
        }
      case AppRoutes.productCategoryCampaign:
        await context.read<ProductCatalogCubit>().loadProducts();
      case AppRoutes.latestStores:
        await context.read<StoreCubit>().loadStore();
      case AppRoutes.brandProducts:
        final args = settings.arguments as BrandProductsRouteArgs?;
        await refreshMarket(
          context,
          marketId: args?.marketId,
          classificationId: args?.classificationId,
        );
      case AppRoutes.storeSearch:
        final args = settings.arguments as StoreSearchRouteArgs?;
        await refreshMarket(context, marketId: args?.market.id);
      case AppRoutes.categories:
        final args = settings.arguments as CategoriesRouteArgs?;
        if (args?.categories.isNotEmpty == true) {
          await context.read<HomeCubit>().loadHome();
        } else {
          await context.read<ProductDiscoveryCubit>().loadDiscovery();
        }
      case AppRoutes.search:
        await context.read<ProductDiscoveryCubit>().loadDiscovery();
    }
  }

  static Future<void> refreshMarket(
    BuildContext context, {
    String? marketId,
    String? classificationId,
  }) async {
    final store = context.read<StoreCubit>();
    final offers = context.read<OfferCatalogCubit>();
    await store.loadStore();
    if (!context.mounted) return;
    final id = marketId?.trim() ?? '';
    final category = classificationId?.trim() ?? '';
    await Future.wait([
      if (id.isNotEmpty) store.ensureMarket(id),
      if (id.isEmpty && category.isNotEmpty)
        store.ensureClassification(category),
      offers.loadOffers(),
    ]);
  }

  static Future<void> refreshTab(BuildContext context, int index) async {
    if (index == 0) {
      await Future.wait([
        context.read<HomeCubit>().loadHome(),
        context.read<ProductCatalogCubit>().loadProducts(),
        context.read<StoreCubit>().loadStore(),
      ]);
    } else if (index == 1) {
      await context.read<StoreCubit>().loadStore();
    }
  }
}
