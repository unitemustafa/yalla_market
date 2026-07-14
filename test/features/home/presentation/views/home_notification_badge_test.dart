import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/home/domain/entities/home_data.dart';
import 'package:yalla_market/features/home/domain/repositories/home_repository.dart';
import 'package:yalla_market/features/home/domain/usecases/get_home_usecase.dart';
import 'package:yalla_market/features/home/presentation/cubit/home_cubit.dart';
import 'package:yalla_market/features/home/presentation/cubit/home_state.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_cubit.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_state.dart';
import 'package:yalla_market/features/home/presentation/views/home_view.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/brand_data.dart';
import 'package:yalla_market/features/store/domain/entities/category_data.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/domain/repositories/product_repository.dart';
import 'package:yalla_market/features/store/domain/repositories/store_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_brands_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/get_categories_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/get_products_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/search_products_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/product_catalog_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/product_discovery_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_cubit.dart';

import '../../../../helpers/auth_widget_fakes.dart';
import '../../../../helpers/cubit_factories.dart';
import '../../helpers/notification_test_helpers.dart';

void main() {
  group('home notification badge', () {
    testWidgets('home header fits a compact iPhone viewport', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cubit = SpyNotificationCubit()
        ..seed(const NotificationState(unreadCount: 100));
      addTearDown(cubit.close);

      await _pumpHome(tester, cubit);

      expect(
        find.byKey(const ValueKey('notification_bell_button')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('unreadCount 0 hides badge', (tester) async {
      final cubit = SpyNotificationCubit()
        ..seed(const NotificationState(unreadCount: 0));
      addTearDown(cubit.close);

      await _pumpHome(tester, cubit);

      expect(
        find.byKey(const ValueKey('notification_bell_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification_unread_badge')),
        findsNothing,
      );
    });

    testWidgets('unreadCount 1 shows 1', (tester) async {
      final cubit = SpyNotificationCubit()
        ..seed(const NotificationState(unreadCount: 1));
      addTearDown(cubit.close);

      await _pumpHome(tester, cubit);

      expect(
        find.byKey(const ValueKey('notification_unread_badge')),
        findsOneWidget,
      );
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('unreadCount 99 shows 99', (tester) async {
      final cubit = SpyNotificationCubit()
        ..seed(const NotificationState(unreadCount: 99));
      addTearDown(cubit.close);

      await _pumpHome(tester, cubit);

      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('unreadCount 100 shows 99+', (tester) async {
      final cubit = SpyNotificationCubit()
        ..seed(const NotificationState(unreadCount: 100));
      addTearDown(cubit.close);

      await _pumpHome(tester, cubit);

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('mark read decreases badge count', (tester) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [
              testNotification(id: 1, isRead: false),
              testNotification(id: 2, isRead: false),
            ],
            unreadCount: 2,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpHome(tester, cubit);
      expect(find.text('2'), findsOneWidget);

      await cubit.markNotificationRead(1);
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('mark all hides badge', (tester) async {
      final cubit = SpyNotificationCubit()
        ..seed(
          NotificationState(
            notifications: [testNotification(isRead: false)],
            unreadCount: 1,
            hasLoaded: true,
          ),
        );
      addTearDown(cubit.close);

      await _pumpHome(tester, cubit);
      await cubit.markAllRead();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('notification_unread_badge')),
        findsNothing,
      );
    });

    testWidgets('clear hides badge', (tester) async {
      final cubit = SpyNotificationCubit()
        ..seed(const NotificationState(unreadCount: 3));
      addTearDown(cubit.close);

      await _pumpHome(tester, cubit);
      cubit.clear();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('notification_unread_badge')),
        findsNothing,
      );
    });
  });
}

Future<void> _pumpHome(
  WidgetTester tester,
  NotificationCubit notificationCubit,
) async {
  final locationRepository = FakeLocationRepository();
  final productRepository = _EmptyProductRepository();
  final storeRepository = _EmptyStoreRepository();
  final cartCubit = makeCartCubit();
  final homeCubit = _BadgeHomeCubit(GetHomeUseCase(_EmptyHomeRepository()))
    ..seedFailure();
  final locationCubit = LocationCubit(locationUseCases(locationRepository));
  final productCatalogCubit = ProductCatalogCubit(
    GetProductsUseCase(productRepository),
    locationUseCases(locationRepository).getSelectedCity,
  );
  final productDiscoveryCubit = ProductDiscoveryCubit(
    getProducts: GetProductsUseCase(productRepository),
    searchProducts: SearchProductsUseCase(productRepository),
    getCategories: GetCategoriesUseCase(productRepository),
    getBrands: GetBrandsUseCase(productRepository),
    getSelectedCity: locationUseCases(locationRepository).getSelectedCity,
  );
  final storeCubit = StoreCubit(GetStoreUseCase(storeRepository));

  addTearDown(cartCubit.close);
  addTearDown(homeCubit.close);
  addTearDown(locationCubit.close);
  addTearDown(productCatalogCubit.close);
  addTearDown(productDiscoveryCubit.close);
  addTearDown(storeCubit.close);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>.value(value: homeCubit),
        BlocProvider<CartCubit>.value(value: cartCubit),
        BlocProvider<LocationCubit>.value(value: locationCubit),
        BlocProvider<NotificationCubit>.value(value: notificationCubit),
        BlocProvider<ProductCatalogCubit>.value(value: productCatalogCubit),
        BlocProvider<ProductDiscoveryCubit>.value(value: productDiscoveryCubit),
        BlocProvider<StoreCubit>.value(value: storeCubit),
      ],
      child: const MaterialApp(home: HomeView()),
    ),
  );
  await tester.pump();
}

class _EmptyHomeRepository implements HomeRepository {
  @override
  Future<ApiResult<HomeData>> getHome() async {
    return const ApiResult.success(
      HomeData(location: null, offers: [], categories: [], products: []),
    );
  }
}

class _BadgeHomeCubit extends HomeCubit {
  _BadgeHomeCubit(super.getHomeUseCase);

  void seedFailure() {
    emit(const HomeFailure('Home disabled in badge test.'));
  }
}

class _EmptyProductRepository implements ProductRepository {
  @override
  Future<ApiResult<List<ProductData>>> getProducts({String? citySlug}) async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<ProductData>> getProduct(String idOrSlug) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<List<ProductData>>> searchProducts(
    String query, {
    String? citySlug,
  }) async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<List<CategoryData>>> getCategories() async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<List<BrandData>>> getBrands() async {
    return const ApiResult.success([]);
  }
}

class _EmptyStoreRepository implements StoreRepository {
  @override
  Future<ApiResult<StoreData>> getStore() async {
    return const ApiResult.success(
      StoreData(
        commonClassifications: [],
        classifications: [],
        marketsByClassificationId: {},
      ),
    );
  }
}
