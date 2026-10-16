import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:yalla_market/core/domain/computation_executor.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/app/app_providers.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/app_router.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/theme/app_theme.dart';
import 'package:yalla_market/features/home/domain/repositories/home_repository.dart';
import 'package:yalla_market/features/home/domain/repositories/notification_repository.dart';
import 'package:yalla_market/features/location/domain/repositories/location_repository.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';
import 'package:yalla_market/features/navigation/presentation/views/navigation_menu_view.dart';
import 'package:yalla_market/features/offers/domain/repositories/offer_repository.dart';
import 'package:yalla_market/features/search/domain/repositories/catalog_search_repository.dart';
import 'package:yalla_market/features/store/domain/repositories/order_repository.dart';
import 'package:yalla_market/features/store/domain/repositories/product_repository.dart';
import 'package:yalla_market/features/store/domain/repositories/store_repository.dart';
import 'package:yalla_market/features/store/domain/repositories/store_products_repository.dart';
import 'package:yalla_market/features/store/domain/entities/store_product_page.dart';
import 'package:yalla_market/features/store/domain/usecases/get_my_orders_usecase.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/market_wishlist_repository.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/market_wishlist_cubit.dart';

import '../features/home/helpers/notification_test_helpers.dart';
import 'stress_fixtures.dart';
import 'stress_repositories.dart';

Future<void> configureStressApp(StressFixtures fixtures) async {
  SharedPreferences.setMockInitialValues({});
  await sl.reset();
  // Widget tests use fake async. Physical profile runs exercise real isolates.
  if (!kProfileMode) {
    sl.registerSingleton<ComputationExecutor>(
      const InlineComputationExecutor(),
    );
  }
  sl.registerSingleton<ProductRepository>(StressProductRepository(fixtures));
  sl.registerSingleton<StoreRepository>(StressStoreRepository(fixtures));
  sl.registerSingleton<StoreProductsRepository>(
    _StressStoreProductsRepository(fixtures),
  );
  sl.registerSingleton<HomeRepository>(StressHomeRepository(fixtures));
  sl.registerSingleton<LocationRepository>(StressLocationRepository());
  sl.registerSingleton<OfferRepository>(StressOfferRepository());
  sl.registerSingleton<WishlistRepository>(StressWishlistRepository(fixtures));
  sl.registerSingleton<MarketWishlistRepository>(
    StressMarketWishlistRepository(fixtures),
  );
  sl.registerSingleton<NotificationRepository>(
    FakeNotificationRepository(notifications: fixtures.notifications),
  );
  sl.registerSingleton<OrderRepository>(StressOrderRepository(fixtures));
  initServiceLocator();
  await sl.unregister<CatalogSearchRepository>();
  sl.registerSingleton<CatalogSearchRepository>(
    StressSearchRepository(fixtures),
  );

  // Use the seeded history directly, without adding bundled demo history.
  await sl.unregister<GetMyOrdersUseCase>();
  sl.registerLazySingleton(() => GetMyOrdersUseCase(sl<OrderRepository>()));
  AuthGuard.setAuthenticated();
}

class _StressStoreProductsRepository implements StoreProductsRepository {
  const _StressStoreProductsRepository(this._fixtures);
  final StressFixtures _fixtures;

  @override
  Future<ApiResult<StoreProductPage>> getProducts(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = _fixtures.products
        .where((product) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              product.title.toLowerCase().contains(normalizedQuery) ||
              product.description.toLowerCase().contains(normalizedQuery);
          return matchesQuery &&
              (subcategoryId == null || product.subcategoryId == subcategoryId);
        })
        .toList(growable: false);
    final start = ((page - 1) * pageSize).clamp(0, filtered.length);
    final end = (start + pageSize).clamp(0, filtered.length);
    return ApiResult.success(
      StoreProductPage(
        products: filtered.sublist(start, end),
        count: filtered.length,
        hasMore: end < filtered.length,
      ),
    );
  }
}

class StressApp extends StatefulWidget {
  const StressApp({super.key, this.home = const NavigationMenuView()});
  final Widget home;
  @override
  State<StressApp> createState() => _StressAppState();
}

class _StressAppState extends State<StressApp> {
  bool _initialized = false;
  @override
  Widget build(BuildContext context) => AppProviders(
    child: Builder(
      builder: (context) {
        if (!_initialized) {
          _initialized = true;
          final location = context.read<LocationCubit>();
          location.syncCity(StressLocationRepository.city);
          location.consumeGpsSuggestionSlot();
          context.read<CartCubit>().loadCartForUser('performance-fixture');
          context.read<WishlistCubit>().loadWishlistForUser(
            'performance-fixture',
          );
          context.read<MarketWishlistCubit>().loadForUser(
            'performance-fixture',
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRouter.generateRoute,
          home: widget.home,
        );
      },
    ),
  );
}
