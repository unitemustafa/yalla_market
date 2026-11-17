import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_router.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/app/routing/double_back_to_exit.dart';
import 'package:yalla_market/core/presentation/widgets/refresh_on_return.dart';
import 'package:yalla_market/features/app_media/presentation/app_media_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';
import 'package:yalla_market/features/store/presentation/views/product_detail_view.dart';

void main() {
  tearDown(AuthGuard.clearAuthentication);

  group('AppRouter', () {
    testWidgets('container and named product routes preserve all arguments', (
      tester,
    ) async {
      AuthGuard.setAuthenticated();
      const settings = RouteSettings(
        name: AppRoutes.productDetail,
        arguments: ProductDetailRouteArgs(
          productId: 'product-42',
          productSlug: 'product-slug',
          initialVariantId: 'variant-2',
          image: 'product.webp',
          title: 'Product',
          brand: 'Market',
          price: '100',
          oldPrice: '120',
          discount: '10%',
        ),
      );
      final pages = await _resolvePages(tester, settings);
      for (final page in pages) {
        final details = (page as DoubleBackToExit).child as ProductDetailView;
        expect(details.productId, 'product-42');
        expect(details.productSlug, 'product-slug');
        expect(details.initialVariantId, 'variant-2');
        expect(details.image, 'product.webp');
        expect(details.title, 'Product');
        expect(details.brand, 'Market');
        expect(details.price, '100');
        expect(details.oldPrice, '120');
        expect(details.discount, '10%');
      }
    });

    testWidgets('container and named market routes retain refresh and IDs', (
      tester,
    ) async {
      AuthGuard.setAuthenticated();
      const settings = RouteSettings(
        name: AppRoutes.brandProducts,
        arguments: BrandProductsRouteArgs(
          brand: 'Market',
          logo: 'market.webp',
          productCount: '12',
          shopId: 'shop-1',
          classificationId: 'food',
          marketId: 'market-42',
        ),
      );
      final pages = await _resolvePages(tester, settings);
      for (final page in pages) {
        final back = (page as RefreshOnReturn).child as DoubleBackToExit;
        final market = back.child as BrandProductsView;
        expect(market.brand, 'Market');
        expect(market.logo, 'market.webp');
        expect(market.productCount, '12');
        expect(market.marketId, 'market-42');
        expect(market.classificationId, 'food');
        expect(market.shopId, 'shop-1');
      }
    });

    for (final name in [AppRoutes.productDetail, AppRoutes.brandProducts]) {
      testWidgets('expired authentication guards both paths to $name', (
        tester,
      ) async {
        AuthGuard.setAuthenticated();
        AuthGuard.clearAuthentication();
        final pages = await _resolvePages(tester, RouteSettings(name: name));
        for (final page in pages) {
          // Do not mount the lazy login provider: this assertion also ensures
          // no catalog refresh is requested for an unauthenticated destination.
          expect(
            (page as DoubleBackToExit).child,
            isA<BlocProvider<AppMediaCubit>>(),
          );
        }
      });
    }

    for (final args in [
      null,
      'invalid',
      const ProductDetailRouteArgs(
        productId: ' ',
        image: '',
        title: '',
        brand: '',
        price: '',
      ),
    ]) {
      testWidgets('invalid product arguments show the fallback ($args)', (
        tester,
      ) async {
        AuthGuard.setAuthenticated();
        final pages = await _resolvePages(
          tester,
          RouteSettings(name: AppRoutes.productDetail, arguments: args),
        );
        for (final page in pages) {
          expect((page as DoubleBackToExit).child, isA<Scaffold>());
        }
      });
    }

    test('generates production flow routes', () {
      const routeNames = [
        AppRoutes.navigationMenu,
        AppRoutes.cart,
        AppRoutes.checkout,
        AppRoutes.processingOrder,
        AppRoutes.paymentSuccess,
        AppRoutes.search,
        AppRoutes.allProducts,
        AppRoutes.categories,
        AppRoutes.latestStores,
        AppRoutes.profile,
        AppRoutes.notifications,
        AppRoutes.addresses,
        AppRoutes.orders,
        AppRoutes.appPreferences,
      ];

      for (final routeName in routeNames) {
        final route = AppRouter.generateRoute(RouteSettings(name: routeName));

        expect(route, isA<MaterialPageRoute<dynamic>>());
      }
    });

    test('generates routes that require typed arguments', () {
      final productRoute = AppRouter.generateRoute(
        const RouteSettings(
          name: AppRoutes.productDetail,
          arguments: ProductDetailRouteArgs(
            productId: 'product-1',
            image: 'asset.png',
            title: 'Demo product',
            brand: 'Demo brand',
            price: 'EGP 10.00',
          ),
        ),
      );
      final brandRoute = AppRouter.generateRoute(
        const RouteSettings(
          name: AppRoutes.brandProducts,
          arguments: BrandProductsRouteArgs(
            brand: 'Demo brand',
            logo: 'asset.png',
            productCount: '3 products',
          ),
        ),
      );
      final categoryCampaignRoute = AppRouter.generateRoute(
        const RouteSettings(
          name: AppRoutes.productCategoryCampaign,
          arguments: ProductCategoryCampaignRouteArgs(
            categoryId: 'category-1',
            categoryName: 'وجبات',
          ),
        ),
      );

      expect(productRoute, isA<MaterialPageRoute<dynamic>>());
      expect(brandRoute, isA<MaterialPageRoute<dynamic>>());
      expect(categoryCampaignRoute, isA<MaterialPageRoute<dynamic>>());
    });

    test('keeps route generation safe when required arguments are missing', () {
      final productRoute = AppRouter.generateRoute(
        const RouteSettings(name: AppRoutes.productDetail),
      );
      final brandRoute = AppRouter.generateRoute(
        const RouteSettings(name: AppRoutes.brandProducts),
      );
      final categoryCampaignRoute = AppRouter.generateRoute(
        const RouteSettings(name: AppRoutes.productCategoryCampaign),
      );

      expect(productRoute, isA<MaterialPageRoute<dynamic>>());
      expect(brandRoute, isA<MaterialPageRoute<dynamic>>());
      expect(categoryCampaignRoute, isA<MaterialPageRoute<dynamic>>());
    });

    test('builds product details arguments from notification data', () {
      final args = ProductDetailRouteArgs.fromNotificationData({
        'product_name': 'كشري مخصوص',
        'market_name': 'محل المدينة',
        'image': '/media/products/koshary.webp',
        'price_text': 'EGP 80',
        'discount': '10.00',
      }, productId: '44');

      expect(args.productId, '44');
      expect(args.title, 'كشري مخصوص');
      expect(args.brand, 'محل المدينة');
      expect(args.price, 'EGP 80');
      expect(args.discount, '10%');
    });
  });
}

Future<List<Widget>> _resolvePages(
  WidgetTester tester,
  RouteSettings settings,
) async {
  final pages = <Widget>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          pages.add(AppRouter.buildContainerPage(context, settings));
          final route = AppRouter.generateRoute(settings) as MaterialPageRoute;
          pages.add(route.builder(context));
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return pages;
}
