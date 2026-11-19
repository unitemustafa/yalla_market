import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/cart/presentation/views/cart_view.dart';
import 'package:yalla_market/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:yalla_market/features/home/presentation/cubit/notification_cubit.dart';
import 'package:yalla_market/features/home/presentation/views/home_view.dart';
import 'package:yalla_market/features/navigation/presentation/views/navigation_menu_view.dart';
import 'package:yalla_market/features/search/presentation/cubit/catalog_search_cubit.dart';
import 'package:yalla_market/features/search/presentation/cubit/catalog_search_state.dart';
import 'package:yalla_market/features/search/presentation/views/search_view.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/presentation/cubit/checkout_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/checkout_state.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_state.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_products_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_state.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';
import 'package:yalla_market/features/store/presentation/views/checkout_view.dart';
import 'package:yalla_market/features/store/presentation/views/orders/orders_view.dart';
import 'package:yalla_market/features/store/presentation/views/product_detail_view.dart';
import 'package:yalla_market/features/store/presentation/views/store_view.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/market_wishlist_cubit.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:yalla_market/features/wishlist/presentation/views/wishlist_view.dart';

import 'stress_app.dart';
import 'stress_fixtures.dart';

typedef AuditAction = Future<void> Function(int iteration);
typedef AuditMeasure =
    Future<void> Function(
      String scenario,
      AuditAction action, {
      AuditAction? prepare,
    });

class CustomerAuditScenarios {
  CustomerAuditScenarios(this.tester, this.measure, {required this.large});

  final WidgetTester tester;
  final AuditMeasure measure;
  final bool large;
  late final fixtures = StressFixtures(
    productCount: large ? 1000 : 120,
    listCount: large ? 1000 : 120,
  );

  Future<void> run() async {
    try {
      await _home();
      await _search();
      await _market();
      await _productAndCart();
      await _favorites();
      await _ordersAndCheckout();
    } finally {
      await _unmount();
    }
  }

  Future<void> _unmount() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    AuthGuard.clearAuthentication();
    await sl.reset();
  }

  Future<void> _mount(Widget home) async {
    await _unmount();
    await configureStressApp(fixtures);
    await tester.pumpWidget(StressApp(home: home));
    await tester.pumpAndSettle();
  }

  NavigatorState get _nav => tester.state(find.byType(Navigator).first);

  Future<void> _pop() async {
    _nav.pop();
    await tester.pumpAndSettle();
  }

  Future<void> _tap(Finder finder) async {
    expect(finder.hitTestable(), findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder _vertical() => find
      .byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      )
      .first;

  Future<void> _scroll() async {
    final scroll = _vertical();
    final position = tester.state<ScrollableState>(scroll).position;
    final before = position.pixels;
    final direction = position.extentAfter > 50 ? -1.0 : 1.0;
    await tester.drag(scroll, Offset(0, direction * 300));
    await tester.pumpAndSettle();
    expect((position.pixels - before).abs(), greaterThan(10));
  }

  Future<void> _home() async {
    await _mount(const Scaffold());
    await measure(
      'home_open',
      (_) async {
        unawaited(
          _nav.push<void>(
            MaterialPageRoute(builder: (_) => const NavigationMenuView()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(HomeView), findsOneWidget);
      },
      prepare: (_) async {
        if (_nav.canPop()) await _pop();
      },
    );
    final home = find.byType(HomeView);
    final notifications = tester.element(home).read<NotificationCubit>();
    final banner = find.byKey(const ValueKey('notification_unread_badge'));
    await measure('home_unread_badge', (i) async {
      final unread = i.isEven ? 3 : 7;
      notifications.emit(notifications.state.copyWith(unreadCount: unread));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: banner, matching: find.text('$unread')),
        findsOneWidget,
      );
    });
    final store = tester.element(home).read<StoreCubit>();
    await measure('home_unrelated_market_update', (_) async {
      final before = store.state.data!;
      // The shared Cubit changes details, keeping the summary list references.
      store.emit(
        StoreReady(
          before.copyWith(
            marketsByClassificationId: {
              ...before.marketsByClassificationId,
              'audit': [fixtures.markets[1]],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        store.state.data!.marketsByClassificationId['audit'],
        hasLength(1),
      );
    });
    await measure('tab_switch', (_) async {
      await _tap(find.text('Store').last);
      expect(find.byType(StoreView), findsOneWidget);
      await _tap(find.text('Home').last);
      expect(find.byType(HomeView), findsOneWidget);
    });
    await measure('home_scroll', (_) => _scroll());
    await measure(
      'product_card_open_close',
      (_) async {
        final cards = find.byType(ProductCardVertical).hitTestable();
        expect(cards, findsWidgets);
        await tester.tap(cards.first);
        await tester.pumpAndSettle();
        expect(find.byType(ProductDetailView), findsOneWidget);
        await _pop();
        expect(home, findsOneWidget);
      },
      prepare: (_) async {
        final position = tester.state<ScrollableState>(_vertical()).position;
        position.jumpTo(0);
        await tester.pumpAndSettle();
      },
    );
  }

  Future<void> _search() async {
    await _mount(
      BlocProvider(
        create: (_) => sl<CatalogSearchCubit>(),
        child: const SearchView(),
      ),
    );
    final cubit = tester
        .element(find.byType(SearchView))
        .read<CatalogSearchCubit>();
    final input = tester.state<EditableTextState>(find.byType(EditableText));
    void type(String text) => input.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
    await measure(
      'search_typing',
      (_) async {
        for (final query in ['P', 'Pr', 'Pro', 'Prod', 'Product']) {
          type(query);
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(input.widget.controller.text, 'Product');
        expect(
          cubit.state.query,
          isEmpty,
          reason: 'Typing window ends before debounce',
        );
      },
      prepare: (_) async {
        type('');
        await tester.pumpAndSettle();
      },
    );
    await measure(
      'search_results',
      (_) async {
        type('Product');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(cubit.state, isA<CatalogSearchReady>());
      },
      prepare: (_) async {
        type('');
        await tester.pumpAndSettle();
      },
    );
    await _tap(find.byKey(const ValueKey('search_filter_products')));
    await measure(
      'search_load_more',
      (_) async {
        final before = cubit.state.results.products.length;
        await cubit.loadMore();
        await tester.pumpAndSettle();
        expect(cubit.state.results.products.length, greaterThan(before));
      },
      prepare: (_) async {
        await cubit.search('Product');
        await tester.pumpAndSettle();
      },
    );
  }

  Future<void> _market() async {
    await _mount(const Scaffold());
    await measure('market_open_close', (_) async {
      unawaited(
        _nav.pushNamed<void>(
          AppRoutes.brandProducts,
          arguments: const BrandProductsRouteArgs(
            brand: 'Store 0',
            logo: '',
            productCount: '',
            marketId: '1',
            classificationId: 'stress',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BrandProductsView), findsOneWidget);
      await _pop();
    });
    unawaited(
      _nav.pushNamed<void>(
        AppRoutes.brandProducts,
        arguments: const BrandProductsRouteArgs(
          brand: 'Store 0',
          logo: '',
          productCount: '',
          marketId: '1',
          classificationId: 'stress',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await measure('market_category', (i) async {
      final id = i.isEven ? 'odd' : 'even';
      final tab = find.byKey(ValueKey('store_subcategory_$id'));
      await tester.ensureVisible(tab);
      await tester.pumpAndSettle();
      await _tap(tab);
      final feed = tester
          .element(find.byType(ProductCardVertical).first)
          .read<StoreProductsCubit>();
      expect(feed.state.products, isNotEmpty);
      expect(
        feed.state.products.every((item) => item.subcategoryId == id),
        isTrue,
      );
    });
    final feed = tester
        .element(find.byType(ProductCardVertical).first)
        .read<StoreProductsCubit>();
    final snapshot = feed.state;
    await measure(
      'market_pagination_flag',
      (_) async {
        feed.emit(
          StoreProductsState(
            products: snapshot.products,
            visibleProducts: snapshot.visibleProducts,
            count: snapshot.count,
            selectionKey: snapshot.selectionKey,
            hasMore: snapshot.hasMore,
            loadingMore: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(feed.state.loadingMore, isTrue);
      },
      prepare: (_) async {
        feed.emit(snapshot);
        await tester.pumpAndSettle();
      },
    );
  }

  Future<void> _productAndCart() async {
    await _mount(
      const ProductDetailView(
        productId: '1',
        image: '',
        title: 'Product',
        brand: 'Store',
        price: '10',
      ),
    );
    final product = find.byType(ProductDetailView);
    final cart = tester.element(product).read<CartCubit>();
    final add = find.byType(ElevatedButton);
    bool canAdd() => tester.widget<ElevatedButton>(add).onPressed != null;
    await measure('product_quantity', (_) async {
      await _tap(find.byIcon(AppIcons.add).last);
      expect(canAdd(), isTrue);
    });
    await measure(
      'product_add_to_cart',
      (_) async {
        await _tap(add);
        expect(cart.state, isNotEmpty);
      },
      prepare: (_) async {
        await cart.clearLocalCart();
        if (!canAdd()) {
          await _tap(find.byIcon(AppIcons.add).last);
        }
      },
    );

    await _mount(const CartView());
    final cartCubit = tester.element(find.byType(CartView)).read<CartCubit>();
    for (final item in _cartItems(large ? 40 : 8)) {
      await cartCubit.addItem(item, item.quantity);
    }
    await tester.pumpAndSettle();
    final plus = find.descendant(
      of: find.byType(CartItemCard).first,
      matching: find.byIcon(AppIcons.add),
    );
    await measure('cart_increment_first_row', (_) async {
      final previous = cartCubit.state.first.quantity;
      await _tap(plus);
      expect(cartCubit.state.first.quantity, previous + 1);
    });
  }

  List<CartItemData> _cartItems(int count) => [
    for (final product in fixtures.products.take(count))
      CartItemData(
        id: product.id,
        productId: product.id,
        variantId: product.defaultVariantId,
        image: product.image,
        title: product.title,
        brand: product.brand,
        price: product.priceValue,
        quantity: 1,
      ),
  ];

  Future<void> _favorites() async {
    await _mount(const WishlistView());
    final context = tester.element(find.byType(WishlistView));
    final markets = context.read<MarketWishlistCubit>();
    final products = context.read<WishlistCubit>();
    await measure('wishlist_toggle_market', (_) async {
      final count = markets.state.items.length;
      await markets.toggle(fixtures.markets.first);
      await tester.pumpAndSettle();
      expect(markets.state.items.length, isNot(count));
    });
    final item = fixtures.wishlist.first;
    await measure('wishlist_toggle_product', (_) async {
      final wasFavorite = products.isFavorite(item.productId);
      await products.toggleItem(item);
      await tester.pumpAndSettle();
      expect(products.isFavorite(item.productId), !wasFavorite);
    });
  }

  Future<void> _ordersAndCheckout() async {
    await _mount(const OrdersView());
    final orders = tester
        .element(find.byType(OrdersView))
        .read<OrderHistoryCubit>();
    OrderHistoryReady orderState(bool loading) => OrderHistoryReady(
      fixtures.orders,
      totalCount: fixtures.orders.length + 1,
      deliveredCount: 0,
      hasMore: true,
      loadingMore: loading,
    );
    await measure(
      'orders_pagination_flag',
      (_) async {
        orders.emit(orderState(true));
        await tester.pumpAndSettle();
        expect((orders.state as OrderHistoryReady).loadingMore, isTrue);
      },
      prepare: (_) async {
        orders.emit(orderState(false));
        await tester.pumpAndSettle();
      },
    );

    await _mount(const CheckoutView(useDemoRepositories: true));
    final context = tester.element(find.byType(CheckoutView));
    final checkout = context.read<CheckoutCubit>();
    final cart = _cartItems(large ? 300 : 8);
    context.read<CartCubit>().emit(List.unmodifiable(cart));
    final preview = OrderPreviewData.fromJson({
      'summary': {'subtotal': 6000, 'grand_total': 6000},
      'market_groups': [
        {
          'delivery_available': true,
          'selected_products': [
            for (final item in cart)
              {
                'variant_id': item.variantId,
                'product_name': item.title,
                'unit_price': item.price,
              },
          ],
        },
      ],
    });
    checkout.emit(CheckoutInitial(preview: preview));
    await tester.pumpAndSettle();
    await measure('checkout_status', (_) async {
      checkout.emit(CheckoutLoading(preview: preview));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(checkout.state, isA<CheckoutLoading>());
      checkout.emit(CheckoutInitial(preview: preview));
      await tester.pumpAndSettle();
    });
  }
}
