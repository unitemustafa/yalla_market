import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/offers/domain/entities/offer_data.dart';
import 'package:yalla_market/features/offers/domain/repositories/offer_repository.dart';
import 'package:yalla_market/features/offers/domain/usecases/get_offers_usecase.dart';
import 'package:yalla_market/features/offers/presentation/cubit/offer_catalog_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_product_page.dart';
import 'package:yalla_market/features/store/domain/repositories/store_repository.dart';
import 'package:yalla_market/features/store/domain/repositories/store_products_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_products_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_products_cubit.dart';

/// Supplies real storefront presentation dependencies without network access.
class CatalogNavigationHarness {
  CatalogNavigationHarness({
    required List<StoreMarketData> markets,
    required ValueChanged<BrandProductsRouteArgs> onOpened,
  }) : observer = _CatalogObserver(onOpened),
       store = StoreCubit(GetStoreUseCase(_StoreRepository(markets))),
       offers = OfferCatalogCubit(const GetOffersUseCase(_EmptyOffers())) {
    AuthGuard.setAuthenticated();
    sl.registerFactory<StoreProductsCubit>(
      () => StoreProductsCubit(const GetStoreProductsUseCase(_EmptyProducts())),
    );
  }

  final NavigatorObserver observer;
  final StoreCubit store;
  final OfferCatalogCubit offers;

  Widget wrap(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: store),
      BlocProvider.value(value: offers),
    ],
    child: child,
  );

  Future<void> dispose() async {
    AuthGuard.clearAuthentication();
    await store.close();
    await offers.close();
    await sl.unregister<StoreProductsCubit>();
  }
}

class _CatalogObserver extends NavigatorObserver {
  _CatalogObserver(this.onOpened);

  final ValueChanged<BrandProductsRouteArgs> onOpened;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final args = route.settings.arguments;
    if (route.settings.name == AppRoutes.brandProducts &&
        args is BrandProductsRouteArgs) {
      onOpened(args);
    }
  }
}

class _StoreRepository implements StoreRepository {
  const _StoreRepository(this.markets);

  final List<StoreMarketData> markets;

  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async =>
      ApiResult.success(
        StoreData(
          commonClassifications: const [],
          classifications: const [],
          marketsByClassificationId: {'test': markets},
        ),
      );

  @override
  Future<ApiResult<StoreMarketData>> getMarket(String marketId) async =>
      ApiResult.success(markets.firstWhere((market) => market.id == marketId));

  @override
  Future<ApiResult<List<StoreMarketData>>> getClassificationMarkets(
    String classificationId,
  ) async => ApiResult.success(
    markets
        .where((market) => market.classificationId == classificationId)
        .toList(),
  );
}

class _EmptyOffers implements OfferRepository {
  const _EmptyOffers();

  @override
  Future<ApiResult<List<OfferData>>> getOffers() async =>
      const ApiResult.success([]);
}

class _EmptyProducts implements StoreProductsRepository {
  const _EmptyProducts();

  @override
  Future<ApiResult<StoreProductPage>> getProducts(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  }) async => const ApiResult.success(
    StoreProductPage(products: [], count: 0, hasMore: false),
  );
}
