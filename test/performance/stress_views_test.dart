import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards_sliver.dart';
import 'package:yalla_market/features/home/presentation/views/notifications_view.dart';
import 'package:yalla_market/features/navigation/presentation/views/navigation_menu_view.dart';
import 'package:yalla_market/features/search/presentation/cubit/catalog_search_cubit.dart';
import 'package:yalla_market/features/search/presentation/views/search_view.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_products_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/presentation/views/orders/orders_view.dart';
import 'package:yalla_market/features/store/presentation/views/product_detail_view.dart';
import 'package:yalla_market/features/store/presentation/views/orders/widgets/order_list_item.dart';
import 'package:yalla_market/features/store/presentation/widgets/store_market_card.dart';
import 'package:yalla_market/features/wishlist/presentation/views/wishlist_view.dart';

import 'stress_app.dart';
import 'stress_fixtures.dart';

void main() {
  Future<void> mount(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await configureStressApp(StressFixtures());
    addTearDown(() async {
      AuthGuard.clearAuthentication();
      await sl.reset();
    });
    await tester.pumpWidget(StressApp(home: home));
    await tester.pumpAndSettle();
  }

  testWidgets(
    '10000-product storefront builds only visible cards and changes category',
    (tester) async {
      await mount(
        tester,
        const BrandProductsView(
          brand: 'Stress',
          logo: '',
          productCount: '10000',
          classificationId: 'stress',
          marketId: '1',
        ),
      );
      expect(
        find.byType(ProductCardVertical).evaluate().length,
        inInclusiveRange(1, 20),
      );
      expect(find.byType(CustomScrollView), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('store_subcategory_odd')),
      );
      await tester.tap(find.byKey(const ValueKey('store_subcategory_odd')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<ProductCardVertical>(find.byType(ProductCardVertical))
            .every((card) => int.parse(card.productId).isEven),
        isTrue,
      );
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      scroll.jumpTo(scroll.maxScrollExtent);
      await tester.pumpAndSettle();
      final cubit = tester
          .element(find.byType(ProductCardsSliver<ProductData>).first)
          .read<StoreProductsCubit>();
      expect(cubit.state.products, hasLength(60));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '1000 favorite products remain lazy and retain horizontal stores',
    (tester) async {
      await mount(tester, const WishlistView());
      expect(
        find.byType(ProductCardVertical).evaluate().length,
        inInclusiveRange(1, 20),
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('wishlist_stores_horizontal_slider')),
        findsOneWidget,
      );
      expect(find.byType(StoreMarketCard).evaluate().length, lessThan(10));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '1000 notifications are lazy and last notification is reachable',
    (tester) async {
      await mount(tester, const NotificationsView());
      expect(
        find.byType(Dismissible).evaluate().length,
        inInclusiveRange(1, 20),
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      // Variable-height lists refine their estimated extent as we scroll.
      for (var index = 0; index < 4; index++) {
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
      }
      expect(find.text('Notification 999'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search stays lazy across 1000 stores and ten product pages', (
    tester,
  ) async {
    await mount(
      tester,
      BlocProvider(
        create: (_) => sl<CatalogSearchCubit>(),
        child: const SearchView(),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Product');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(
      find.byType(StoreMarketCard).evaluate().length,
      inInclusiveRange(1, 10),
    );
    await tester.tap(find.byKey(const ValueKey('search_filter_products')));
    await tester.pumpAndSettle();
    final cubit = tester
        .element(find.byType(SearchView))
        .read<CatalogSearchCubit>();
    for (var index = 0; index < 9; index++) {
      await cubit.loadMore();
    }
    await tester.pumpAndSettle();
    expect(cubit.state.results.products, hasLength(1000));
    expect(
      find.byType(ProductCardVertical).evaluate().length,
      inInclusiveRange(1, 30),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('1000 orders retain the lazy separated list', (tester) async {
    await mount(tester, const OrdersView());
    expect(
      find.byType(OrderListItem).evaluate().length,
      inInclusiveRange(1, 10),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stress harness exercises real home tabs and product route', (
    tester,
  ) async {
    await mount(tester, const NavigationMenuView());
    for (final label in ['Store', 'Wishlist', 'Home']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed(
      AppRoutes.productDetail,
      arguments: const ProductDetailRouteArgs(
        productId: '1',
        title: 'Product',
        brand: 'Stress',
        price: '10',
        image: '',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailView), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationMenuView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
